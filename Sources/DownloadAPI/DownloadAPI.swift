//
//  DownloadAPI.swift
//
//
//  Created by joker on 2024/1/14.
//

import Foundation

// Linux/Windows 把 URLSession/URLRequest 放在 FoundationNetworking（决策 D8：跨平台）。
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import OpenAPIRuntime
import OpenAPIURLSession
import Common

public struct DownloadAPIClient: Sendable {
    
    private let client = Client(
        serverURL: try! Servers.Server1.url(),
        configuration: .init(dateTranscoder: Common.ISO8601DateTranscoder()),
        transport: URLSessionTransport()
    )
    
    public init() {}
}

public extension DownloadAPIClient {
    
    enum Project: String, CaseIterable {
        case paper
        case travertine
        case waterfall
        case velocity
        case folia
        
        public var name: String { self.rawValue }
    }
    
    func allProjects() async throws -> [Project]? {
        let response = try await client.getProjects()
        switch response {
        case .ok(let output):
            switch output.body {
            case .json(let jsonObj):
                return jsonObj.projects?
                    .compactMap { $0.project?.id }
                    .compactMap { Project(rawValue: $0) }
            }
        default:
            return nil
        }
    }
    
    func latestVersion(project: Project) async throws -> String? {
        let response = try await client.getVersions(path: .init(project: project.name))
        switch response {
        case .ok(let output):
            switch output.body {
            case .json(let jsonObj):
                let latestVersion = jsonObj.versions?.first
                return latestVersion?.version?.id
            }
        default:
            return nil
        }
    }
    
    func latestBuild(project: Project, version: String) async throws -> Int32? {
        
        let response = try await client.getLatestBuild(.init(path: .init(project: project.name, version: version)))
        
        switch response {
        case .ok(let output):
            switch output.body {
            case .json(let jsonObj):
                let latestBuild = jsonObj.id
                return latestBuild
            }
        default:
            break
        }
        return nil
    }
    
    func latestBuildInfo(project: Project, version: String) async throws -> (build: Int32, name: String, sha256: String, downloadUrl: String, sizeBytes: Int32)? {
        guard let latestBuild = try await latestBuild(project: project, version: version)
        else {
            return nil
        }
        
        return try await buildInfo(project: project, version: version, build: latestBuild)
    }
    
    func buildInfo(
        project: Project,
        version: String,
        build: Int32
    ) async throws -> (build: Int32, name: String, sha256: String, downloadUrl: String, sizeBytes: Int32)? {
        let response = try await client.getBuild(.init(path: .init(
            project: project.name,
            version: version,
            build: build
        )))
        switch response {
        case .ok(let output):
            switch output.body {
            case .json(let body):
                guard let downloadInfo = body.downloads?.additionalProperties["server:default"],
                      let name = downloadInfo.name,
                      let sha256 = downloadInfo.checksums?.sha256,
                      let downloadUrl = downloadInfo.url,
                      let sizeBytes = downloadInfo.size
                else {
                    return nil
                }
                return (build, name, sha256, downloadUrl, sizeBytes)
            }
        default:
            return nil
        }
    }
    
    func downloadBuild(
        project: Project,
        version: String,
        build: Int32,
        bufferSize: Int = 5 * 1024
    ) async throws -> (AsyncStream<Result<Data, Error>>, size: Int64)? {
        
        let response = try await buildInfo(project: project, version: version, build: build)
        
        guard let downloadUrl = response?.downloadUrl,
              let downloadURL = URL(string: downloadUrl)
        else {
            return nil
        }
        
        return try await downloadFileWithBuffer(from: downloadURL, bufferSize: bufferSize)
    }
}
