# ``SwiftAlembic``

A modern Swift wrapper for the Alembic 3D interchange library, with
first-class support for every Apple platform.

## Overview

SwiftAlembic bridges to the upstream [Alembic](https://www.alembic.io)
C++ library, exposing a Swift-native API for animated 3D geometry.

SwiftAlembic lets you write and read animated 3D geometry — point clouds,
polygon meshes, subdivision surfaces, curves, NURBS patches, cameras, lights,
xform hierarchies, and face sets — using a Swift-native API built on `simd`
types, Swift 6 concurrency, and `AsyncSequence` iteration.

It runs on **macOS, iOS, visionOS, and tvOS** (arm64) — the same code,
the same `.abc` files, across every Apple platform. The bundled
`Alembic.xcframework` ships device + simulator slices for the entire
family.

| Platform | Minimum | Slices |
|---|---|---|
| macOS | 26 | arm64 (dynamic framework) |
| iOS | 17 | arm64 device + simulator (static) |
| visionOS | 2 | arm64 device + simulator (static) |
| tvOS | 17 | arm64 device + simulator (static) |

### Write a point cloud

```swift
import SwiftAlembic
import simd

try Alembic.withArchive(path: "scene.abc") { archive in
    let writer = archive.top
        .createChild(name: "cloud")
        .addPoints(name: "points")

    var sample = Alembic.PointsSample()
    sample.positions = [
        SIMD3<Float>( 0, 0,  0),
        SIMD3<Float>( 1, 2,  3),
        SIMD3<Float>(-1, 0.5, 2),
    ]
    try writer.set(sample)
}
```

### Read it back, async

```swift
let archive = try Alembic.InputArchive(path: "scene.abc")
if let reader = archive.top.children[0].children[0].asPoints() {
    for try await sample in reader.samples {
        process(sample.positions)
    }
}
```

## Topics

### Getting started

- ``Alembic``
- ``Alembic/withArchive(path:_:)-3ldr3``
- ``Alembic/withArchive(path:_:)-2rnl0``
- ``Alembic/withInputArchive(path:_:)``

### Archives

- ``Alembic/Archive``
- ``Alembic/InputArchive``

### Object hierarchy

- ``Alembic/Object``
- ``Alembic/InputObject``
- ``Alembic/InputObject/Children``
- ``Alembic/SchemaType``

### Polygon meshes

- ``Alembic/PolyMeshWriter``
- ``Alembic/PolyMeshReader``
- ``Alembic/PolyMeshSample``

### Subdivision surfaces

- ``Alembic/SubDWriter``
- ``Alembic/SubDReader``
- ``Alembic/SubDSample``

### Curves

- ``Alembic/CurvesWriter``
- ``Alembic/CurvesReader``
- ``Alembic/CurvesSample``

### Points

- ``Alembic/PointsWriter``
- ``Alembic/PointsReader``
- ``Alembic/PointsSample``

### NURBS patches

- ``Alembic/NuPatchWriter``
- ``Alembic/NuPatchReader``
- ``Alembic/NuPatchSample``

### Xform hierarchies

- ``Alembic/XformWriter``
- ``Alembic/XformReader``
- ``Alembic/XformSample``
- ``Alembic/XformOp``
- ``Alembic/XformOpType``

### Cameras and lights

- ``Alembic/CameraWriter``
- ``Alembic/CameraReader``
- ``Alembic/CameraSample``
- ``Alembic/LightWriter``
- ``Alembic/LightReader``
- ``Alembic/LightSample``

### Face sets

- ``Alembic/FaceSetWriter``
- ``Alembic/FaceSetReader``
- ``Alembic/FaceSetSample``

### Async sample iteration

- ``Alembic/SampledReader``
- ``Alembic/SampleSequence``

### Geometry primitives

- ``Alembic/Box3d``

### Errors

- ``Alembic/Error``
