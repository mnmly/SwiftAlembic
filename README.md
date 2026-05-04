# SwiftAlembic

A Swift wrapper for the [Alembic](https://www.alembic.io) 3D interchange library.
Write and read animated geometry — point clouds, meshes, curves, cameras, xforms, and more —
using a modern Swift API with SIMD types, Swift 6 concurrency, and `AsyncSequence` iteration.

## Requirements

| | |
|---|---|
| Platform | macOS 13+ (arm64) |
| Swift | 6.2+ |
| Xcode | 16+ |

The bundled `Alembic.xcframework` is **arm64/macOS only**. Multi-platform support is not currently in scope.

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/mnmly/SwiftAlembic", from: "0.1.0")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["SwiftAlembic"],
        swiftSettings: [.interoperabilityMode(.Cxx)]
    )
]
```

> Swift/C++ interoperability mode is required because SwiftAlembic bridges to C++ via `std::shared_ptr`.

## Quick Start

### Writing

```swift
import SwiftAlembic
import simd

// Scoped write — archive is flushed automatically when the closure returns.
try Alembic.withArchive(path: "scene.abc") { archive in
    let obj = archive.top.createChild(name: "cloud")
    let writer = obj.addPoints(name: "points")

    var sample = Alembic.PointsSample()
    sample.positions = [
        SIMD3<Float>(0, 0, 0),
        SIMD3<Float>(1, 2, 3),
        SIMD3<Float>(-1, 0.5, 2),
    ]
    try writer.set(sample)
}
```

### Reading

```swift
let archive = try Alembic.InputArchive(path: "scene.abc")
let obj = archive.top.children[0]          // random-access, no upfront allocation
let schemaObj = obj.children[0]
print(schemaObj.schemaType)                // .points

if let reader = schemaObj.asPoints() {
    print(reader.sampleCount)             // number of time samples
    let s = try reader.sample(at: 0)
    print(s.positions)                    // [SIMD3<Float>]
}
```

### Async iteration over samples

```swift
if let reader = schemaObj.asPoints() {
    for try await sample in reader.samples {
        process(sample.positions)
    }
}
```

## API Overview

### Archives

| Type | Description |
|---|---|
| `Alembic.Archive` | Write archive (OArchive) |
| `Alembic.InputArchive` | Read archive (IArchive) |
| `Alembic.withArchive(path:_:)` | Scoped write — flushes on scope exit |
| `Alembic.withInputArchive(path:_:)` | Scoped read |

### Object hierarchy

| Type | Description |
|---|---|
| `Alembic.Object` | Write object node; create children and add schemas |
| `Alembic.InputObject` | Read object node; query schema type and children |
| `InputObject.children` | `RandomAccessCollection` — lazy, no upfront array |
| `InputObject.schemaType` | `Alembic.SchemaType` enum |

### Schemas

| Schema | Writer | Reader | Sample |
|---|---|---|---|
| PolyMesh | `PolyMeshWriter` | `PolyMeshReader` | `PolyMeshSample` |
| SubD | `SubDWriter` | `SubDReader` | `SubDSample` |
| Curves | `CurvesWriter` | `CurvesReader` | `CurvesSample` |
| Points | `PointsWriter` | `PointsReader` | `PointsSample` |
| NuPatch | `NuPatchWriter` | `NuPatchReader` | `NuPatchSample` |
| Xform | `XformWriter` | `XformReader` | `XformSample` |
| Camera | `CameraWriter` | `CameraReader` | `CameraSample` |
| Light | `LightWriter` | `LightReader` | `LightSample` |
| FaceSet | `FaceSetWriter` | `FaceSetReader` | `FaceSetSample` |

Add a writer to an object node:

```swift
let writer = obj.addPolyMesh(name: "mesh")
let reader = inputObj.asPolyMesh()          // returns nil if schema doesn't match
```

Every reader type conforms to `Alembic.SampledReader` and gains a `.samples` `AsyncSequence`.

### Geometric types

SwiftAlembic uses standard `simd` types throughout — no custom vector types.

| Alembic concept | Swift type |
|---|---|
| Position / Normal / Velocity | `SIMD3<Float>` |
| UV | `SIMD2<Float>` |
| Translation / double-precision | `SIMD3<Double>` |
| Bounding box | `Alembic.Box3d` (min/max as `SIMD3<Double>`) |

### Error handling

All throwing calls produce `Alembic.Error`, which conforms to `LocalizedError`:

```swift
do {
    let archive = try Alembic.InputArchive(path: "missing.abc")
} catch let e as Alembic.Error {
    print(e)  // "File not found: …"
}
```

## Recipes

### Multi-frame animated mesh

```swift
try Alembic.withArchive(path: "anim.abc") { archive in
    let writer = archive.top.createChild(name: "geo").addPolyMesh(name: "mesh")
    for frame in 0..<timeline.count {
        var s = Alembic.PolyMeshSample()
        s.positions  = timeline[frame].positions
        s.faceIndices = topology.faceIndices
        s.faceCounts  = topology.faceCounts
        try writer.set(s)
    }
}
```

### Xform hierarchy

```swift
let root = archive.top.createChild(name: "root")
let xformWriter = root.addXform(name: "xform")

var xform = Alembic.XformSample()
xform.ops = [
    .init(type: .translate, values: [0, 10, 0]),
    .init(type: .rotate,    values: [0, 1, 0, 45]),
]
try xformWriter.set(xform)

// Geometry hangs under the xform object
let child = root.createChild(name: "geo")
try child.addPolyMesh(name: "mesh").set(meshSample)
```

### Walking the object tree

```swift
func walk(_ obj: Alembic.InputObject, depth: Int = 0) {
    let indent = String(repeating: "  ", count: depth)
    print("\(indent)\(obj.name)  [\(obj.schemaType)]")
    for child in obj.children {          // RandomAccessCollection — zero allocation
        walk(child, depth: depth + 1)
    }
}
walk(archive.top)
```

### Async write scheduling

```swift
func exportAsync(path: String, frames: [Frame]) async throws {
    try await Alembic.withArchive(path: path) { archive in
        let writer = archive.top.createChild(name: "cloud").addPoints(name: "pts")
        for frame in frames {
            var s = Alembic.PointsSample()
            s.positions = frame.positions
            try writer.set(s)
        }
    }
}
```

## Examples

The package includes a runnable example that writes a 120-frame animated point cloud
(4,000 particles across three orbital shells) and reads it back using async iteration:

```sh
swift run Examples [output.abc]
```

Output defaults to `/tmp/point_cloud_animation.abc` if no path is given.

## Thread safety

`Alembic.Archive`, `Alembic.InputArchive`, and all writer/reader types are **not thread-safe**.
Confine all access to a single thread or serial queue. An actor-isolated wrapper is planned for a future release.

## License

MIT — see [LICENSE](LICENSE).
