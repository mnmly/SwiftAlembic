# SwiftAlembic Audit — Correctness Findings

Audit performed against the v0 implementation. Build (`swift build`) and `swift test` both pass (4/4), but the tests do not prove what the report claims they prove, and several writers are silently broken.

## Critical (must fix)

### C1. Tests do not verify round-trip data
Every test only inspects names in the object hierarchy. None of the readers (`PolyMeshReader`, `PointsReader`, `XformReader`, `CurvesReader`) are exercised — positions, faceIndices, normals, IDs, xform op values are never read back and asserted.

- Evidence: `Tests/SwiftAlembicTests/SwiftAlembicTests.swift:5-85`
- Acceptance: each test reads the schema back via the typed reader and asserts the written values match (positions, indices, op values, etc.).

### C2. Reader API is unreachable from Swift
`AlembicInputObject` exposes only `name`, `fullName`, `children`. There is **no Swift method to obtain a `PolyMeshReader` / `XformReader` / etc. from an `AlembicInputObject`**. The C wrappers `calembic_object_as_polymesh`, `calembic_object_schema_type`, etc. exist but nothing in Swift calls them. The entire read API (`sample(at:)`, `sampleCount`) is dead code from a Swift consumer's perspective. This is the root cause of C1.

- Evidence: `Sources/SwiftAlembic/SwiftAlembic.swift:61-70`
- Fix: add typed cast methods plus a schema-type query on `AlembicInputObject`. See API design doc, item D12.

### C3. `calembic_light_set` is a no-op
The function catches an exception that can't happen and never invokes `light->light.getSchema().set(...)`. Light writes produce zero samples on disk. `calembic_light_get` likewise constructs a default `CAlembicLightSample` and never reads the schema.

- Evidence: `Sources/CAlembic/calembic_light.cpp:12-15` (set), `:26-29` (get)
- Fix: actually call the schema's `set` / `get`.

### C4. Camera write bug — selfBounds overwrites childBounds
```cpp
if (sample.hasChildBounds) s.setChildBounds(toBox3d(sample.childBounds));
if (sample.selfBoundsSet)  s.setChildBounds(toBox3d(sample.selfBounds));   // copy-paste error
```
The second call overwrites the legitimate `setChildBounds` with the user's selfBounds. Note `CameraSample` has no `setSelfBounds` — selfBounds is computed.

- Evidence: `Sources/CAlembic/calembic_camera.cpp:22-23`
- Fix: remove line 23 (or remove `selfBoundsSet`/`selfBounds` from `CAlembicCameraSample` entirely; alembic computes camera self bounds).

## Medium

### M1. Points auto-generates IDs unconditionally
When `hasIds == false`, the writer fills sequential IDs (0..N-1). On read, `hasIds` will then always be `true`, surprising users who never set IDs.

- Evidence: `Sources/CAlembic/calembic_points.cpp:21-25`
- Fix: either document the behavior, or only auto-generate when alembic strictly requires IDs (it does — but consider hiding this behind an Optional in Swift so the surface stays clean).

### M2. Hardcoded geometry param scopes
- PolyMesh UVs forced to `kFacevaryingScope`, normals to `kVertexScope`.
- Curves UVs forced to `kVertexScope`.

No way to override. Acceptable for v0; flag for follow-up.

### M3. Static error state with mutex is racy by construction
Two threads calling Alembic across the same global error slot can trample each other's last-error between `throw` and the Swift-side read. Mutex guarantees no torn reads but does not guarantee the message you read corresponds to the call you made.

- Evidence: `Sources/CAlembic/calembic_util.cpp`
- Fix: thread an out-error parameter (or return a struct `{ int code; std::string msg; }`) per call. This eliminates the mutex too.

### M4. `calembic_object_schema_type` not surfaced to Swift
Without it, users cannot dispatch on schema type while traversing.

- Evidence: declared in `Sources/CAlembic/include/calembic.h:69`, never wrapped.

## Low

### L1. FaceSet placement
`OFaceSet` is created as a child of any `OObject`. In Alembic FaceSets normally live under a PolyMesh or SubD. Not enforced; consumer can write semantically odd files. Document.

### L2. `requires cplusplus` modulemap with C++ types in the public header
`std::shared_ptr`, `std::vector`, `std::string` in the public C header — this is a C++ wrapper consumed via Swift Cxx interop, not a C wrapper. Naming (`CAlembic`) is misleading; consider `AlembicCXX`. Cosmetic.

### L3. `var top: AlembicObject { .init(...) }` reallocates on every access
Same for `children`. Caches would be cheap and idiomatic.

## Verification story

Whoever picks this up should add round-trip tests **before** fixing anything else, so we have a regression net. Suggested coverage:
- PolyMesh: positions + faceIndices + faceCounts + normals + uvs.
- Points: positions + (auto-generated) ids + custom ids.
- Curves: positions + vertsPerCurve + curveType + basis.
- Xform: translate, rotate, scale, matrix — verify op type and channel values.
- Camera: focalLength + apertures + childBounds.
- SubD: positions + creases.
- Light: write + read and assert sampleCount > 0 (currently fails, exposes C3).
- FaceSet: faceIndices.
