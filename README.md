# PaperMC

[![][spi-swift-badge]][repo_url] [![][spi-platform-badge]][repo_url]

API for [PaperMC][PaperMC] and Plugin Platform [Hangar][Hangar], include: 

1. [DownloadAPI][DownloadAPI] - [OpenAPI Spec][DownloadAPI OpenAPI Spec]

2. [HangarAPI][HangarAPI] - [OpenAPI Spec][Hangar OpenAPI Spec]

## Usage

```swift

import PackageDescription

let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/OrzMC/PaperMC.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "Your Target Name",
            dependencies: [
                .product(name: "DownloadAPI", package: "PaperMC"),
                .product(name: "HangarAPI", package: "PaperMC"),
                ...
            ]),
    ]
    ...
)

```


[PaperMC]: <https://papermc.io/>
[Hangar]: <https://hangar.papermc.io/>

[DownloadAPI]: <https://fill.papermc.io/swagger-ui/index.html#/>
[DownloadAPI OpenAPI Spec]: <https://fill.papermc.io/openapi.yaml>

[HangarAPI]: <https://hangar.papermc.io/api-docs>
[Hangar OpenAPI Spec]: <https://hangar.papermc.io/v3/api-docs/public>

[spi-swift-badge]: <https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FOrzMC%2FPaperMC%2Fbadge%3Ftype%3Dswift-versions>
[spi-platform-badge]: <https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FOrzMC%2FPaperMC%2Fbadge%3Ftype%3Dplatforms>
[repo_url]: <https://swiftpackageindex.com/OrzMC/PaperMC>
