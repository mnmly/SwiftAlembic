// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SwiftAlembic",
    platforms: [
        .macOS(.v26),
        .iOS(.v17),
        .visionOS(.v2),
        .tvOS(.v17)
    ],
    products: [
        .library(name: "SwiftAlembic", targets: ["SwiftAlembic"]),
        .executable(name: "Examples", targets: ["Examples"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.3")
    ],
    targets: [
        .binaryTarget(
            name: "Alembic",
            url: "https://github.com/mnmly/alembic-xcframework-builder/releases/download/1.8.11-multiplatform/Alembic.xcframework.zip",
            checksum: "73f73447a3e0103bb16f9b7f7c3549f40579b822620764fe3f3802a8e9df0f87"
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
            exclude: ["AlembicApp"],
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
