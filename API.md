# SwiftAlembic API Reference

All public types live inside the `Alembic` namespace (`public enum Alembic`).

---

## Table of Contents

1. [Namespace and module setup](#namespace-and-module-setup)
2. [Error handling](#error-handling)
3. [Geometric types](#geometric-types)
4. [Archives](#archives)
5. [Object hierarchy](#object-hierarchy)
6. [Schema types](#schema-types)
7. [Schemas](#schemas)
   - [PolyMesh](#polymesh)
   - [SubD](#subd)
   - [Curves](#curves)
   - [Points](#points)
   - [NuPatch](#nupatch)
   - [Xform](#xform)
   - [Camera](#camera)
   - [Light](#light)
   - [FaceSet](#faceset)
8. [Sample iteration](#sample-iteration)
9. [Scoped archive API](#scoped-archive-api)
10. [Thread safety](#thread-safety)
11. [Deprecated aliases](#deprecated-aliases)

---

## Namespace and module setup

Every public type is nested under the `Alembic` enum, which acts as a namespace.

```swift
import SwiftAlembic
import simd
```

> Your target must set `.interoperabilityMode(.Cxx)` in its `swiftSettings` because
> SwiftAlembic bridges to C++ via `std::shared_ptr`.

---

## Error handling

```swift
public enum Alembic.Error: Swift.Error, LocalizedError, CustomStringConvertible
```

Thrown by all operations that can fail. Conforms to `LocalizedError` so Foundation
and SwiftUI error presentation work out of the box.

### Cases

| Case | When thrown |
|---|---|
| `.fileNotFound(String)` | Path does not exist or cannot be created |
| `.alreadyOpen(String)` | Archive is already open |
| `.invalidSchema(String)` | Object does not have the expected schema |
| `.invalidSample(String)` | Sample data is malformed |
| `.internalError(String)` | Unexpected Alembic C++ exception |

### Properties

```swift
var description: String        // human-readable message
var errorDescription: String?  // same; satisfies LocalizedError
```

### Usage

```swift
do {
    let archive = try Alembic.InputArchive(path: "missing.abc")
} catch let e as Alembic.Error {
    switch e {
    case .fileNotFound(let msg): print("not found:", msg)
    default: print(e)
    }
}
```

---

## Geometric types

SwiftAlembic uses standard `simd` types for all geometry — no custom vector structs.

| Concept | Swift type |
|---|---|
| 3-D position / normal / velocity | `SIMD3<Float>` |
| 2-D UV coordinate | `SIMD2<Float>` |
| Double-precision position (xform) | `SIMD3<Double>` |
| Axis-aligned bounding box | `Alembic.Box3d` |

### `Alembic.Box3d`

```swift
public struct Alembic.Box3d: Sendable {
    public var min: SIMD3<Double>
    public var max: SIMD3<Double>
    public init(min: SIMD3<Double>, max: SIMD3<Double>)
}
```

Used for the `selfBounds` / `childBounds` fields on mesh samples.

---

## Archives

### `Alembic.Archive` — write

```swift
public final class Alembic.Archive
```

Wraps an Ogawa/HDF5 output archive. **Not thread-safe** — confine to one thread.

```swift
// Properties
public let handle: AlembicOArchivePtr          // underlying C++ shared_ptr (advanced use)
public private(set) lazy var top: Alembic.Object  // root object; initialised on first access
```

```swift
// Initialiser
public init(path: String) throws
```

The C++ archive is flushed and closed when the Swift object is deallocated.
Prefer `Alembic.withArchive` to guarantee timely flushing.

---

### `Alembic.InputArchive` — read

```swift
public final class Alembic.InputArchive
```

```swift
public let handle: AlembicIArchivePtr
public private(set) lazy var top: Alembic.InputObject
public init(path: String) throws
```

---

## Object hierarchy

### `Alembic.Object` — write node

```swift
public final class Alembic.Object
```

A node in the write-side scene hierarchy. Obtain the root via `Archive.top`; create
deeper nodes with `createChild`.

```swift
// Create a child group node
@discardableResult
public func createChild(name: String) -> Alembic.Object

// Attach a schema to this node and return the writer
@discardableResult public func addPolyMesh(name: String) -> Alembic.PolyMeshWriter
@discardableResult public func addSubD(name: String)     -> Alembic.SubDWriter
@discardableResult public func addCurves(name: String)   -> Alembic.CurvesWriter
@discardableResult public func addPoints(name: String)   -> Alembic.PointsWriter
@discardableResult public func addNuPatch(name: String)  -> Alembic.NuPatchWriter
@discardableResult public func addXform(name: String)    -> Alembic.XformWriter
@discardableResult public func addCamera(name: String)   -> Alembic.CameraWriter
@discardableResult public func addLight(name: String)    -> Alembic.LightWriter
@discardableResult public func addFaceSet(name: String)  -> Alembic.FaceSetWriter
```

A node can hold **one schema** and any number of child nodes.

---

### `Alembic.InputObject` — read node

```swift
public final class Alembic.InputObject
```

```swift
// Identity
public var name: String        // local name (e.g. "mesh")
public var fullName: String    // full path (e.g. "/group/mesh")
public var schemaType: Alembic.SchemaType

// Children — RandomAccessCollection; no upfront array allocation
public var children: Alembic.InputObject.Children

// Cast to a typed reader (returns nil if schema doesn't match)
public func asPolyMesh() -> Alembic.PolyMeshReader?
public func asSubD()     -> Alembic.SubDReader?
public func asCurves()   -> Alembic.CurvesReader?
public func asPoints()   -> Alembic.PointsReader?
public func asNuPatch()  -> Alembic.NuPatchReader?
public func asXform()    -> Alembic.XformReader?
public func asCamera()   -> Alembic.CameraReader?
public func asLight()    -> Alembic.LightReader?
public func asFaceSet()  -> Alembic.FaceSetReader?
```

### `Alembic.InputObject.Children`

```swift
public struct Alembic.InputObject.Children: RandomAccessCollection
// Element = Alembic.InputObject, Index = Int
```

Fetches child objects on demand via the C++ layer — no `[InputObject]` array is
allocated until you actually subscript or iterate.

```swift
let count = obj.children.count        // O(1) — reads child count from C++
let first = obj.children[0]           // O(1) — fetches single child
for child in obj.children { ... }     // iterates without materialising the array
```

---

## Schema types

```swift
public enum Alembic.SchemaType: Sendable {
    case unknown
    case polyMesh
    case subD
    case curves
    case points
    case nuPatch
    case xform
    case camera
    case light
    case faceSet
}
```

Read from `InputObject.schemaType`. A plain group node (no schema attached) reports `.unknown`.

---

## Schemas

Every schema follows the same pattern:

- A **Sample** value type (`Sendable`) carries per-frame data.
- A **Writer** (`final class`) appends samples in call order; each call is one time sample.
- A **Reader** (`final class`) provides random-access and `AsyncSequence` access to stored samples.

Writers return `Self` (discardable), so calls can be chained:

```swift
try writer.set(sample0).set(sample1).set(sample2)
```

---

### PolyMesh

Polygonal mesh with optional normals, UVs, velocities, and bounding box.

```swift
public struct Alembic.PolyMeshSample: Sendable {
    public var positions:   [SIMD3<Float>]    // required; one entry per vertex
    public var faceIndices: [Int32]           // required; vertex indices, concatenated per face
    public var faceCounts:  [Int32]           // required; vertex count per face
    public var normals:     [SIMD3<Float>]?   // one per vertex, or nil
    public var uvs:         [SIMD2<Float>]?   // one per vertex, or nil
    public var velocities:  [SIMD3<Float>]?   // one per vertex, or nil
    public var selfBounds:  Alembic.Box3d?
    public init()
}

public final class Alembic.PolyMeshWriter {
    @discardableResult
    public func set(_ s: Alembic.PolyMeshSample) throws -> Self
}

public final class Alembic.PolyMeshReader: Alembic.SampledReader {
    public var sampleCount: Int
    public func sample(at idx: Int) throws -> Alembic.PolyMeshSample
    public var samples: Alembic.SampleSequence<Alembic.PolyMeshReader> { get }
}
```

**Topology note**: `faceIndices` is a flat array; `faceCounts[i]` tells how many vertices
face `i` has. For a quad: `faceCounts = [4]`, `faceIndices = [0, 1, 2, 3]`.

---

### SubD

Subdivision surface. Same topology fields as PolyMesh; subdivision is applied by
the consumer (DCC, renderer).

```swift
public struct Alembic.SubDSample: Sendable {
    public var positions:   [SIMD3<Float>]
    public var faceIndices: [Int32]
    public var faceCounts:  [Int32]
    public init()
}

public final class Alembic.SubDWriter {
    @discardableResult
    public func set(_ s: Alembic.SubDSample) throws -> Self
}

public final class Alembic.SubDReader: Alembic.SampledReader {
    public var sampleCount: Int
    public func sample(at idx: Int) throws -> Alembic.SubDSample
    public var samples: Alembic.SampleSequence<Alembic.SubDReader> { get }
}
```

---

### Curves

One or more B-spline / linear curves sharing a single position array.

```swift
public struct Alembic.CurvesSample: Sendable {
    public var positions:     [SIMD3<Float>]  // control points, all curves concatenated
    public var vertsPerCurve: [Int32]         // point count for each curve
    public init()
}

public final class Alembic.CurvesWriter {
    @discardableResult
    public func set(_ s: Alembic.CurvesSample) throws -> Self
}

public final class Alembic.CurvesReader: Alembic.SampledReader {
    public var sampleCount: Int
    public func sample(at idx: Int) throws -> Alembic.CurvesSample
    public var samples: Alembic.SampleSequence<Alembic.CurvesReader> { get }
}
```

---

### Points

Unordered particle / point cloud.

```swift
public struct Alembic.PointsSample: Sendable {
    public var positions: [SIMD3<Float>]
    public init()
}

public final class Alembic.PointsWriter {
    @discardableResult
    public func set(_ s: Alembic.PointsSample) throws -> Self
}

public final class Alembic.PointsReader: Alembic.SampledReader {
    public var sampleCount: Int
    public func sample(at idx: Int) throws -> Alembic.PointsSample
    public var samples: Alembic.SampleSequence<Alembic.PointsReader> { get }
}
```

---

### NuPatch

Non-uniform rational B-spline surface.

```swift
public struct Alembic.NuPatchSample: Sendable {
    public var positions: [SIMD3<Float>]
    public init()
}

public final class Alembic.NuPatchWriter {
    @discardableResult
    public func set(_ s: Alembic.NuPatchSample) throws -> Self
}

public final class Alembic.NuPatchReader: Alembic.SampledReader {
    public var sampleCount: Int
    public func sample(at idx: Int) throws -> Alembic.NuPatchSample
    public var samples: Alembic.SampleSequence<Alembic.NuPatchReader> { get }
}
```

---

### Xform

Transform node carrying a stack of typed operations.

```swift
public enum Alembic.XformOpType: Sendable {
    case translate   // values: [x, y, z]
    case rotate      // values: [axisX, axisY, axisZ, angleDegrees]
    case scale       // values: [sx, sy, sz]
    case matrix      // values: [m00…m33] row-major, up to 16 doubles
}

public struct Alembic.XformOp: Sendable {
    public var type:   Alembic.XformOpType
    public var values: [Double]               // up to 16 elements
    public init(type: Alembic.XformOpType, values: [Double])
}

public struct Alembic.XformSample: Sendable {
    public var ops:      [Alembic.XformOp]
    public var inherits: Bool                 // whether to inherit parent transform (default true)
    public init()
}

public final class Alembic.XformWriter {
    @discardableResult
    public func set(_ s: Alembic.XformSample) throws -> Self
}

public final class Alembic.XformReader: Alembic.SampledReader {
    public var sampleCount: Int
    public func sample(at idx: Int) throws -> Alembic.XformSample
    public var samples: Alembic.SampleSequence<Alembic.XformReader> { get }
}
```

**Example — TRS stack**:

```swift
var xform = Alembic.XformSample()
xform.ops = [
    .init(type: .translate, values: [0, 5, 0]),
    .init(type: .rotate,    values: [0, 1, 0, 45]),  // Y-axis, 45°
    .init(type: .scale,     values: [2, 2, 2]),
]
```

---

### Camera

Thin-lens camera. Currently exposes focal length; the Alembic schema supports additional
parameters (aperture, near/far, etc.) which can be added as `CameraSample` fields in a
future version.

```swift
public struct Alembic.CameraSample: Sendable {
    public var focalLength: Double   // millimetres (default 35)
    public init()
}

public final class Alembic.CameraWriter {
    @discardableResult
    public func set(_ s: Alembic.CameraSample) throws -> Self
}

public final class Alembic.CameraReader: Alembic.SampledReader {
    public var sampleCount: Int
    public func sample(at idx: Int) throws -> Alembic.CameraSample
    public var samples: Alembic.SampleSequence<Alembic.CameraReader> { get }
}
```

---

### Light

Presence-only light schema. Alembic stores light data as a camera sample internally;
SwiftAlembic exposes it as an empty sample type so the object appears in the scene tree.

```swift
public struct Alembic.LightSample: Sendable {
    public init()
}

public final class Alembic.LightWriter {
    @discardableResult
    public func set(_: Alembic.LightSample) throws -> Self
}

public final class Alembic.LightReader: Alembic.SampledReader {
    public var sampleCount: Int
    public func sample(at idx: Int) throws -> Alembic.LightSample
    public var samples: Alembic.SampleSequence<Alembic.LightReader> { get }
}
```

---

### FaceSet

A named subset of faces within a mesh, referenced by face index.

```swift
public struct Alembic.FaceSetSample: Sendable {
    public var faceIndices: [Int32]   // indices into the parent mesh's face array
    public init()
}

public final class Alembic.FaceSetWriter {
    @discardableResult
    public func set(_ s: Alembic.FaceSetSample) throws -> Self
}

public final class Alembic.FaceSetReader: Alembic.SampledReader {
    public var sampleCount: Int
    public func sample(at idx: Int) throws -> Alembic.FaceSetSample
    public var samples: Alembic.SampleSequence<Alembic.FaceSetReader> { get }
}
```

---

## Sample iteration

All reader types conform to `Alembic.SampledReader` and gain a `.samples` property.

### `Alembic.SampledReader`

```swift
public protocol Alembic.SampledReader<Sample>: AnyObject {
    associatedtype Sample
    var sampleCount: Int { get }
    func sample(at idx: Int) throws -> Sample
}
```

### `Alembic.SampleSequence<R>`

```swift
public struct Alembic.SampleSequence<R: Alembic.SampledReader>: AsyncSequence
// Element = R.Sample
```

Default extension on all conforming readers:

```swift
public var samples: Alembic.SampleSequence<Self> { get }
```

**Usage**:

```swift
// Index-based (synchronous)
for i in 0..<reader.sampleCount {
    let s = try reader.sample(at: i)
}

// AsyncSequence (works in async contexts)
for try await sample in reader.samples {
    process(sample)
}
```

Both approaches are equivalent in performance; the `AsyncSequence` path reads samples
synchronously inside the iterator and does not spawn background work.

---

## Scoped archive API

These functions ensure the archive is closed (and any pending data flushed) as soon as
the closure returns — even if it throws — without relying on ARC timing.

### `Alembic.withArchive` (sync)

```swift
@discardableResult
public static func Alembic.withArchive<T>(
    path: String,
    _ body: (Alembic.Archive) throws -> T
) throws -> T
```

### `Alembic.withInputArchive`

```swift
@discardableResult
public static func Alembic.withInputArchive<T>(
    path: String,
    _ body: (Alembic.InputArchive) throws -> T
) throws -> T
```

### `Alembic.withArchive` (async)

```swift
@discardableResult
public static func Alembic.withArchive<T: Sendable>(
    path: String,
    _ body: @Sendable (Alembic.Archive) throws -> T
) async throws -> T
```

Lets write workflows be scheduled from `async` call sites. The body still executes
synchronously on the calling cooperative thread — Alembic I/O is not async internally.

**Example**:

```swift
// Sync
try Alembic.withArchive(path: "out.abc") { archive in
    try archive.top.createChild(name: "geo")
        .addPolyMesh(name: "mesh")
        .set(sample)
}

// From an async context
try await Alembic.withArchive(path: "out.abc") { archive in
    try archive.top.createChild(name: "geo")
        .addPoints(name: "pts")
        .set(cloudSample)
}
```

---

## Thread safety

`Alembic.Archive`, `Alembic.InputArchive`, and all writer/reader types are **not
thread-safe**. All access must occur on a single thread or a serial queue.

An actor-isolated wrapper is planned for a future release.

---

## Deprecated aliases

These flat typealiases are provided for source compatibility with code written before
the `Alembic` namespace was introduced. They will be removed in the next major version.

| Deprecated | Replacement |
|---|---|
| `AlembicArchive` | `Alembic.Archive` |
| `AlembicInputArchive` | `Alembic.InputArchive` |
| `AlembicObject` | `Alembic.Object` |
| `AlembicInputObject` | `Alembic.InputObject` |
| `AlembicError` | `Alembic.Error` |
| `AlembicSchemaType` | `Alembic.SchemaType` |
