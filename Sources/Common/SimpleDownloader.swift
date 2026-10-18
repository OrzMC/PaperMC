import Foundation

// Linux/Windows 的 Foundation 把 URLSession 放进 FoundationNetworking（决策 D8：Swift CLI 跨平台）。
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// 带缓冲的下载流：返回值里 `size` 是**总字节数**（不定长时为 -1），`stream` 按 `bufferSize` 分块。
///
/// 平台差异：Apple 平台用 `URLSession.bytes(from:)` 真流式；corelibs-foundation（Linux/Windows）
/// 没有 async bytes API，退化为「整包 `data(from:)` → 本地分块投递」——语义（分块顺序、`size`、
/// 错误位置）保持一致，但首字节延迟变成整包时间。
public func downloadFileWithBuffer(
    from url: URL,
    bufferSize: Int = 512 * 1024
) async throws -> (stream: AsyncStream<Result<Data, Error>>, size: Int64) {
    #if canImport(FoundationNetworking)
    let (data, response) = try await URLSession.shared.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200
    else {
        throw URLError(.badServerResponse)
    }

    let stream = AsyncStream(Result<Data, Error>.self) { continuation in
        Task {
            var offset = 0
            while offset < data.count {
                let end = min(offset + bufferSize, data.count)
                continuation.yield(.success(data.subdata(in: offset..<end)))
                offset = end
            }
            continuation.finish()
        }
    }

    return (stream, Int64(data.count))
    #else
    let (bytes, response) = try await URLSession.shared.bytes(from: url)

    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200
    else {
        throw URLError(.badServerResponse)
    }

    guard let contentLength = httpResponse.value(forHTTPHeaderField: "Content-Length").flatMap(Int64.init)
    else {
        throw URLError(.cannotParseResponse)
    }

    let stream = AsyncStream(Result<Data, Error>.self) { continuation in
        Task {
            var buffer = Data(capacity: bufferSize)
            do {
                for try await byte in bytes {
                    buffer.append(byte)
                    if buffer.count >= bufferSize {
                        continuation.yield(.success(buffer))
                        buffer.removeAll(keepingCapacity: true)
                    }
                }
                // 发送剩余数据
                if !buffer.isEmpty {
                    continuation.yield(.success(buffer))
                }
                continuation.finish()
            } catch {
                continuation.yield(.failure(error))
                continuation.finish()
            }
        }
    }

    return (stream, contentLength)
    #endif
}
