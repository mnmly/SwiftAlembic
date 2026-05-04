// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SwiftAlembic",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "SwiftAlembic", targets: ["SwiftAlembic"])
    ],
    targets: [
        .binaryTarget(
            name: "Alembic",
            path: "Frameworks/Alembic.xcframework"
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
