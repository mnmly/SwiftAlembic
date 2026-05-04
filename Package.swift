// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SwiftAlembic",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "SwiftAlembic", targets: ["SwiftAlembic"]),
        .executable(name: "Examples", targets: ["Examples"])
    ],
    targets: [
        .binaryTarget(
            name: "Alembic",
            url: "https://github.com/mnmly/alembic-xcframework-builder/releases/download/1.81.11-fix/Alembic.xcframework.zip",
            checksum: "4a10cf92c8c4a542644c6317d9487736c277b20bd19bf43ff780318bfa7fd46b"
        ),
        .target(
            name: "CAlembic",
            dependencies: ["Alembic"],
            path: "Sources/CAlembic",
            cxxSettings: [
                .headerSearchPath("include")
            ]
        ),
        .target(
            name: "SwiftAlembic",
            dependencies: ["CAlembic"],
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        ),
        .executableTarget(
            name: "Examples",
            dependencies: ["SwiftAlembic"],
            path: "Examples",
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        ),
        .testTarget(
            name: "SwiftAlembicTests",
            dependencies: ["SwiftAlembic"],
            path: "Tests/SwiftAlembicTests",
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        )
    ],
    cxxLanguageStandard: .cxx17
)
