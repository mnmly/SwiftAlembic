// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SwiftAlembic",
    platforms: [
        .macOS(.v15),
        .iOS(.v15),
        .visionOS(.v1),
        .tvOS(.v15)
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
            url: "https://github.com/mnmly/alembic-xcframework-builder/releases/download/1.8.11-multiplatform-min15/Alembic.xcframework.zip",
            checksum: "0f4c0f2a2665a9912bf0ec8f84c32f7a685308c37074da246d43d33850aae50e"
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
