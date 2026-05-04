import CAlembic
import CxxStdlib
import Foundation
import simd

// MARK: - Public namespace

/// Top-level namespace for all SwiftAlembic public types.
public enum Alembic {}

// MARK: - Error

extension Alembic {
    public enum Error: Swift.Error, LocalizedError, CustomStringConvertible {
        case fileNotFound(String), alreadyOpen(String), invalidSchema(String), invalidSample(String), internalError(String)
        public var description: String {
            switch self {
            case .fileNotFound(let m): "File not found: \(m)"
            case .alreadyOpen(let m): "Already open: \(m)"
            case .invalidSchema(let m): "Invalid schema: \(m)"
            case .invalidSample(let m): "Invalid sample: \(m)"
            case .internalError(let m): "Internal: \(m)"
            }
        }
        public var errorDescription: String? { description }
        static func fromLast() -> Alembic.Error {
            let m = String(cString: calembic_last_error())
            switch calembic_last_error_code() {
            case CAlembicError_FileNotFound: return .fileNotFound(m)
            case CAlembicError_AlreadyOpen: return .alreadyOpen(m)
            case CAlembicError_InvalidSchema: return .invalidSchema(m)
            case CAlembicError_InvalidSample: return .invalidSample(m)
            default: return .internalError(m)
            }
        }
        static func check(_ code: Int32) throws { if code != 0 { throw fromLast() } }
    }
}

// MARK: - Geometric types

extension Alembic {
    public struct Box3d: Sendable {
        public var min, max: SIMD3<Double>
        public init(min: SIMD3<Double>, max: SIMD3<Double>) { self.min = min; self.max = max }
    }
}

// MARK: - C++ boundary bridging (internal)

extension SIMD3 where Scalar == Float {
    init(_ c: CAlembicV3f) { self.init(c.x, c.y, c.z) }
    var cxx: CAlembicV3f { CAlembicV3f(x: x, y: y, z: z) }
}
extension SIMD3 where Scalar == Double {
    init(_ c: CAlembicV3d) { self.init(c.x, c.y, c.z) }
    var cxx: CAlembicV3d { CAlembicV3d(x: x, y: y, z: z) }
}
extension SIMD2 where Scalar == Float {
    init(_ c: CAlembicV2f) { self.init(c.x, c.y) }
    var cxx: CAlembicV2f { CAlembicV2f(x: x, y: y) }
}
extension Alembic.Box3d {
    init(_ c: CAlembicBox3d) { self.init(min: SIMD3<Double>(c.min), max: SIMD3<Double>(c.max)) }
    var cxx: CAlembicBox3d { CAlembicBox3d(min: min.cxx, max: max.cxx) }
}

// CAlembicN3f shares the same layout as CAlembicV3f — bridge via the V3f extension.
private extension CAlembicN3f {
    var asV3f: CAlembicV3f { CAlembicV3f(x: x, y: y, z: z) }
}
private func fromN3f(_ n: CAlembicN3f) -> SIMD3<Float> { SIMD3<Float>(n.x, n.y, n.z) }
private func toN3f(_ v: SIMD3<Float>) -> CAlembicN3f { CAlembicN3f(x: v.x, y: v.y, z: v.z) }

// MARK: - Archive + Object

extension Alembic {
    public final class Archive {
        public let handle: AlembicOArchivePtr
        public init(path: String) throws {
            handle = calembic_create_archive(std.string(path))
            if calembic_last_error_code() != CAlembicError_OK { throw Alembic.Error.fromLast() }
        }
        public private(set) lazy var top: Object = .init(ptr: calembic_archive_top_O(handle))
    }

    public final class InputArchive {
        public let handle: AlembicIArchivePtr
        public init(path: String) throws {
            handle = calembic_open_archive(std.string(path))
            if calembic_last_error_code() != CAlembicError_OK { throw Alembic.Error.fromLast() }
        }
        public private(set) lazy var top: InputObject = .init(ptr: calembic_archive_top_I(handle))
    }

    public enum SchemaType: Sendable {
        case unknown, polyMesh, subD, curves, points, nuPatch, xform, camera, light, faceSet
        init(_ c: CAlembicSchemaType) {
            switch c {
            case CAlembicSchema_PolyMesh: self = .polyMesh
            case CAlembicSchema_SubD: self = .subD
            case CAlembicSchema_Curves: self = .curves
            case CAlembicSchema_Points: self = .points
            case CAlembicSchema_NuPatch: self = .nuPatch
            case CAlembicSchema_Xform: self = .xform
            case CAlembicSchema_Camera: self = .camera
            case CAlembicSchema_Light: self = .light
            case CAlembicSchema_FaceSet: self = .faceSet
            default: self = .unknown
            }
        }
    }

    public final class Object {
        public let ptr: AlembicOObjectPtr
        public init(ptr: AlembicOObjectPtr) { self.ptr = ptr }
        @discardableResult public func addPolyMesh(name: String) -> PolyMeshWriter { .init(ptr: calembic_create_polymesh(ptr, std.string(name))) }
        @discardableResult public func addSubD(name: String) -> SubDWriter { .init(ptr: calembic_create_subd(ptr, std.string(name))) }
        @discardableResult public func addCurves(name: String) -> CurvesWriter { .init(ptr: calembic_create_curves(ptr, std.string(name))) }
        @discardableResult public func addPoints(name: String) -> PointsWriter { .init(ptr: calembic_create_points(ptr, std.string(name))) }
        @discardableResult public func addNuPatch(name: String) -> NuPatchWriter { .init(ptr: calembic_create_nupatch(ptr, std.string(name))) }
        @discardableResult public func addXform(name: String) -> XformWriter { .init(ptr: calembic_create_xform(ptr, std.string(name))) }
        @discardableResult public func addCamera(name: String) -> CameraWriter { .init(ptr: calembic_create_camera(ptr, std.string(name))) }
        @discardableResult public func addLight(name: String) -> LightWriter { .init(ptr: calembic_create_light(ptr, std.string(name))) }
        @discardableResult public func addFaceSet(name: String) -> FaceSetWriter { .init(ptr: calembic_create_faceset(ptr, std.string(name))) }
        @discardableResult public func createChild(name: String) -> Object { .init(ptr: calembic_create_child(ptr, std.string(name))) }
    }

    public final class InputObject {
        public let ptr: AlembicIObjectPtr
        public init(ptr: AlembicIObjectPtr) { self.ptr = ptr }
        public var name: String { String(calembic_object_name(ptr)) }
        public var fullName: String { String(calembic_object_full_name(ptr)) }
        public var schemaType: SchemaType { SchemaType(calembic_object_schema_type(ptr)) }

        /// Lazy random-access view of child objects — no array allocation until elements are accessed.
        public var children: Children { Children(ptr) }
        public func asPolyMesh() -> PolyMeshReader? {
            let schema = calembic_object_as_polymesh(ptr)
            guard calembic_last_error_code() == CAlembicError_OK else { return nil }
            return PolyMeshReader(ptr: schema)
        }
        public func asSubD() -> SubDReader? {
            let schema = calembic_object_as_subd(ptr)
            guard calembic_last_error_code() == CAlembicError_OK else { return nil }
            return SubDReader(ptr: schema)
        }
        public func asCurves() -> CurvesReader? {
            let schema = calembic_object_as_curves(ptr)
            guard calembic_last_error_code() == CAlembicError_OK else { return nil }
            return CurvesReader(ptr: schema)
        }
        public func asPoints() -> PointsReader? {
            let schema = calembic_object_as_points(ptr)
            guard calembic_last_error_code() == CAlembicError_OK else { return nil }
            return PointsReader(ptr: schema)
        }
        public func asNuPatch() -> NuPatchReader? {
            let schema = calembic_object_as_nupatch(ptr)
            guard calembic_last_error_code() == CAlembicError_OK else { return nil }
            return NuPatchReader(ptr: schema)
        }
        public func asXform() -> XformReader? {
            let schema = calembic_object_as_xform(ptr)
            guard calembic_last_error_code() == CAlembicError_OK else { return nil }
            return XformReader(ptr: schema)
        }
        public func asCamera() -> CameraReader? {
            let schema = calembic_object_as_camera(ptr)
            guard calembic_last_error_code() == CAlembicError_OK else { return nil }
            return CameraReader(ptr: schema)
        }
        public func asLight() -> LightReader? {
            let schema = calembic_object_as_light(ptr)
            guard calembic_last_error_code() == CAlembicError_OK else { return nil }
            return LightReader(ptr: schema)
        }
        public func asFaceSet() -> FaceSetReader? {
            let schema = calembic_object_as_faceset(ptr)
            guard calembic_last_error_code() == CAlembicError_OK else { return nil }
            return FaceSetReader(ptr: schema)
        }
    }
}

// MARK: - InputObject.Children

extension Alembic.InputObject {
    public struct Children: RandomAccessCollection {
        public typealias Index = Int
        public typealias Element = Alembic.InputObject
        private let ptr: AlembicIObjectPtr
        init(_ ptr: AlembicIObjectPtr) { self.ptr = ptr }
        public var startIndex: Int { 0 }
        public var endIndex: Int { Int(calembic_object_num_children(ptr)) }
        public subscript(i: Int) -> Alembic.InputObject {
            precondition(i >= 0 && i < endIndex, "Index out of range")
            return .init(ptr: calembic_object_child_at(ptr, UInt32(i)))
        }
    }
}

// MARK: - PolyMesh

extension Alembic {
    public struct PolyMeshSample: Sendable {
        public var positions: [SIMD3<Float>] = []
        public var faceIndices: [Int32] = []
        public var faceCounts: [Int32] = []
        public var normals: [SIMD3<Float>]?
        public var uvs: [SIMD2<Float>]?
        public var velocities: [SIMD3<Float>]?
        public var selfBounds: Box3d?
        public init() {}
    }

    public final class PolyMeshWriter {
        let ptr: AlembicOPolyMeshPtr; init(ptr: AlembicOPolyMeshPtr) { self.ptr = ptr }
        @discardableResult public func set(_ s: PolyMeshSample) throws -> Self {
            var c = CAlembicPolyMeshSample()
            for p in s.positions { c.positions.push_back(p.cxx) }
            for v in s.faceIndices { c.faceIndices.push_back(v) }
            for v in s.faceCounts { c.faceCounts.push_back(v) }
            if let n = s.normals { for v in n { c.normals.push_back(toN3f(v)) }; c.hasNormals = true }
            if let u = s.uvs { for v in u { c.uvs.push_back(v.cxx) }; c.hasUVs = true }
            if let v = s.velocities { for v2 in v { c.velocities.push_back(v2.cxx) }; c.hasVelocities = true }
            if let b = s.selfBounds { c.selfBounds = b.cxx; c.selfBoundsSet = true }
            try Alembic.Error.check(calembic_polymesh_set(ptr, c)); return self
        }
    }

    public final class PolyMeshReader {
        let ptr: AlembicIPolyMeshPtr; init(ptr: AlembicIPolyMeshPtr) { self.ptr = ptr }
        public var sampleCount: Int { Int(calembic_polymesh_num_samples(ptr)) }
        public func sample(at idx: Int) throws -> PolyMeshSample {
            var c = CAlembicPolyMeshSample()
            try Alembic.Error.check(calembic_polymesh_get(ptr, UInt32(idx), &c))
            var s = PolyMeshSample()
            for i in 0..<c.positions.size() { s.positions.append(SIMD3<Float>(c.positions[i])) }
            for i in 0..<c.faceIndices.size() { s.faceIndices.append(c.faceIndices[i]) }
            for i in 0..<c.faceCounts.size() { s.faceCounts.append(c.faceCounts[i]) }
            if c.hasNormals { s.normals = (0..<c.normals.size()).map { fromN3f(c.normals[$0]) } }
            if c.hasUVs { s.uvs = (0..<c.uvs.size()).map { SIMD2<Float>(c.uvs[$0]) } }
            if c.hasVelocities { s.velocities = (0..<c.velocities.size()).map { SIMD3<Float>(c.velocities[$0]) } }
            if c.selfBoundsSet { s.selfBounds = Box3d(c.selfBounds) }
            return s
        }
    }
}

// MARK: - Xform

extension Alembic {
    public enum XformOpType: Sendable {
        case translate, rotate, scale, matrix
        var cxx: CAlembicXformOpType {
            switch self {
            case .translate: CAlembicXformOp_Translate
            case .rotate: CAlembicXformOp_Rotate
            case .scale: CAlembicXformOp_Scale
            case .matrix: CAlembicXformOp_Matrix
            }
        }
    }
    public struct XformOp: Sendable {
        public var type: XformOpType; public var values: [Double]
        public init(type: XformOpType, values: [Double]) { self.type = type; self.values = values }
    }
    public struct XformSample: Sendable { public var ops: [XformOp] = []; public var inherits = true; public init() {} }

    public final class XformWriter {
        let ptr: AlembicOXformPtr; init(ptr: AlembicOXformPtr) { self.ptr = ptr }
        @discardableResult public func set(_ s: XformSample) throws -> Self {
            var c = CAlembicXformSample(); c.inherits = s.inherits
            for op in s.ops {
                var co = CAlembicXformOp(); co.type = op.type.cxx
                co.valueCount = Int32(min(op.values.count, 16))
                for i in 0..<min(op.values.count, 16) { co.values[i] = op.values[i] }
                c.ops.push_back(co)
            }
            try Alembic.Error.check(calembic_xform_set(ptr, c)); return self
        }
    }

    public final class XformReader {
        let ptr: AlembicIXformPtr; init(ptr: AlembicIXformPtr) { self.ptr = ptr }
        public var sampleCount: Int { Int(calembic_xform_num_samples(ptr)) }
        public func sample(at idx: Int) throws -> XformSample {
            var c = CAlembicXformSample()
            try Alembic.Error.check(calembic_xform_get(ptr, UInt32(idx), &c))
            var s = XformSample(); s.inherits = c.inherits
            for i in 0..<c.ops.size() {
                let co = c.ops[i]
                let t: XformOpType = switch co.type {
                case CAlembicXformOp_Translate: .translate
                case CAlembicXformOp_Rotate: .rotate
                case CAlembicXformOp_Scale: .scale
                default: .matrix
                }
                var vals: [Double] = []
                for j in 0..<Int(co.valueCount) where j < 16 { vals.append(co.values[j]) }
                s.ops.append(XformOp(type: t, values: vals))
            }
            return s
        }
    }
}

// MARK: - SubD

extension Alembic {
    public struct SubDSample: Sendable {
        public var positions: [SIMD3<Float>] = []
        public var faceIndices: [Int32] = []
        public var faceCounts: [Int32] = []
        public init() {}
    }
    public final class SubDWriter {
        let ptr: AlembicOSubDPtr; init(ptr: AlembicOSubDPtr) { self.ptr = ptr }
        @discardableResult public func set(_ s: SubDSample) throws -> Self {
            var c = CAlembicSubDSample()
            for p in s.positions { c.positions.push_back(p.cxx) }
            for v in s.faceIndices { c.faceIndices.push_back(v) }
            for v in s.faceCounts { c.faceCounts.push_back(v) }
            try Alembic.Error.check(calembic_subd_set(ptr, c)); return self
        }
    }
    public final class SubDReader {
        let ptr: AlembicISubDPtr; init(ptr: AlembicISubDPtr) { self.ptr = ptr }
        public var sampleCount: Int { Int(calembic_subd_num_samples(ptr)) }
        public func sample(at idx: Int) throws -> SubDSample {
            var c = CAlembicSubDSample()
            try Alembic.Error.check(calembic_subd_get(ptr, UInt32(idx), &c))
            var s = SubDSample()
            for i in 0..<c.positions.size() { s.positions.append(SIMD3<Float>(c.positions[i])) }
            for i in 0..<c.faceIndices.size() { s.faceIndices.append(c.faceIndices[i]) }
            for i in 0..<c.faceCounts.size() { s.faceCounts.append(c.faceCounts[i]) }
            return s
        }
    }
}

// MARK: - Curves

extension Alembic {
    public struct CurvesSample: Sendable {
        public var positions: [SIMD3<Float>] = []
        public var vertsPerCurve: [Int32] = []
        public init() {}
    }
    public final class CurvesWriter {
        let ptr: AlembicOCurvesPtr; init(ptr: AlembicOCurvesPtr) { self.ptr = ptr }
        @discardableResult public func set(_ s: CurvesSample) throws -> Self {
            var c = CAlembicCurvesSample()
            for p in s.positions { c.positions.push_back(p.cxx) }
            for v in s.vertsPerCurve { c.vertsPerCurve.push_back(v) }
            try Alembic.Error.check(calembic_curves_set(ptr, c)); return self
        }
    }
    public final class CurvesReader {
        let ptr: AlembicICurvesPtr; init(ptr: AlembicICurvesPtr) { self.ptr = ptr }
        public var sampleCount: Int { Int(calembic_curves_num_samples(ptr)) }
        public func sample(at idx: Int) throws -> CurvesSample {
            var c = CAlembicCurvesSample()
            try Alembic.Error.check(calembic_curves_get(ptr, UInt32(idx), &c))
            var s = CurvesSample()
            for i in 0..<c.positions.size() { s.positions.append(SIMD3<Float>(c.positions[i])) }
            for i in 0..<c.vertsPerCurve.size() { s.vertsPerCurve.append(c.vertsPerCurve[i]) }
            return s
        }
    }
}

// MARK: - Points

extension Alembic {
    public struct PointsSample: Sendable {
        public var positions: [SIMD3<Float>] = []
        public init() {}
    }
    public final class PointsWriter {
        let ptr: AlembicOPointsPtr; init(ptr: AlembicOPointsPtr) { self.ptr = ptr }
        @discardableResult public func set(_ s: PointsSample) throws -> Self {
            var c = CAlembicPointsSample()
            for p in s.positions { c.positions.push_back(p.cxx) }
            try Alembic.Error.check(calembic_points_set(ptr, c)); return self
        }
    }
    public final class PointsReader {
        let ptr: AlembicIPointsPtr; init(ptr: AlembicIPointsPtr) { self.ptr = ptr }
        public var sampleCount: Int { Int(calembic_points_num_samples(ptr)) }
        public func sample(at idx: Int) throws -> PointsSample {
            var c = CAlembicPointsSample()
            try Alembic.Error.check(calembic_points_get(ptr, UInt32(idx), &c))
            var s = PointsSample()
            for i in 0..<c.positions.size() { s.positions.append(SIMD3<Float>(c.positions[i])) }
            return s
        }
    }
}

// MARK: - NuPatch

extension Alembic {
    public struct NuPatchSample: Sendable { public var positions: [SIMD3<Float>] = []; public init() {} }
    public final class NuPatchWriter {
        let ptr: AlembicONuPatchPtr; init(ptr: AlembicONuPatchPtr) { self.ptr = ptr }
        @discardableResult public func set(_ s: NuPatchSample) throws -> Self {
            var c = CAlembicNuPatchSample()
            for p in s.positions { c.positions.push_back(p.cxx) }
            try Alembic.Error.check(calembic_nupatch_set(ptr, c)); return self
        }
    }
    public final class NuPatchReader {
        let ptr: AlembicINuPatchPtr; init(ptr: AlembicINuPatchPtr) { self.ptr = ptr }
        public var sampleCount: Int { Int(calembic_nupatch_num_samples(ptr)) }
        public func sample(at idx: Int) throws -> NuPatchSample {
            var c = CAlembicNuPatchSample()
            try Alembic.Error.check(calembic_nupatch_get(ptr, UInt32(idx), &c))
            var s = NuPatchSample()
            for i in 0..<c.positions.size() { s.positions.append(SIMD3<Float>(c.positions[i])) }
            return s
        }
    }
}

// MARK: - Camera

extension Alembic {
    public struct CameraSample: Sendable { public var focalLength: Double = 35; public init() {} }
    public final class CameraWriter {
        let ptr: AlembicOCameraPtr; init(ptr: AlembicOCameraPtr) { self.ptr = ptr }
        @discardableResult public func set(_ s: CameraSample) throws -> Self {
            var c = CAlembicCameraSample(); c.focalLength = s.focalLength
            try Alembic.Error.check(calembic_camera_set(ptr, c)); return self
        }
    }
    public final class CameraReader {
        let ptr: AlembicICameraPtr; init(ptr: AlembicICameraPtr) { self.ptr = ptr }
        public var sampleCount: Int { Int(calembic_camera_num_samples(ptr)) }
        public func sample(at idx: Int) throws -> CameraSample {
            var c = CAlembicCameraSample()
            try Alembic.Error.check(calembic_camera_get(ptr, UInt32(idx), &c))
            var s = CameraSample(); s.focalLength = c.focalLength; return s
        }
    }
}

// MARK: - Light

extension Alembic {
    public struct LightSample: Sendable { public init() {} }
    public final class LightWriter {
        let ptr: AlembicOLightPtr; init(ptr: AlembicOLightPtr) { self.ptr = ptr }
        @discardableResult public func set(_: LightSample) throws -> Self {
            let c = CAlembicLightSample()
            try Alembic.Error.check(calembic_light_set(ptr, c)); return self
        }
    }
    public final class LightReader {
        let ptr: AlembicILightPtr; init(ptr: AlembicILightPtr) { self.ptr = ptr }
        public var sampleCount: Int { Int(calembic_light_num_samples(ptr)) }
        public func sample(at idx: Int) throws -> LightSample {
            var c = CAlembicLightSample()
            try Alembic.Error.check(calembic_light_get(ptr, UInt32(idx), &c))
            return LightSample()
        }
    }
}

// MARK: - FaceSet

extension Alembic {
    public struct FaceSetSample: Sendable { public var faceIndices: [Int32] = []; public init() {} }
    public final class FaceSetWriter {
        let ptr: AlembicOFaceSetPtr; init(ptr: AlembicOFaceSetPtr) { self.ptr = ptr }
        @discardableResult public func set(_ s: FaceSetSample) throws -> Self {
            var c = CAlembicFaceSetSample()
            for v in s.faceIndices { c.faceIndices.push_back(v) }
            try Alembic.Error.check(calembic_faceset_set(ptr, c)); return self
        }
    }
    public final class FaceSetReader {
        let ptr: AlembicIFaceSetPtr; init(ptr: AlembicIFaceSetPtr) { self.ptr = ptr }
        public var sampleCount: Int { Int(calembic_faceset_num_samples(ptr)) }
        public func sample(at idx: Int) throws -> FaceSetSample {
            var c = CAlembicFaceSetSample()
            try Alembic.Error.check(calembic_faceset_get(ptr, UInt32(idx), &c))
            var s = FaceSetSample()
            for i in 0..<c.faceIndices.size() { s.faceIndices.append(c.faceIndices[i]) }
            return s
        }
    }
}

// MARK: - Scoped archive API (D8)

extension Alembic {
    /// Creates an archive, runs `body`, then closes (flushes) it when `body` returns.
    @discardableResult
    public static func withArchive<T>(path: String, _ body: (Archive) throws -> T) throws -> T {
        let archive = try Archive(path: path)
        return try body(archive)
    }

    /// Opens an archive for reading, runs `body`, then closes it when `body` returns.
    @discardableResult
    public static func withInputArchive<T>(path: String, _ body: (InputArchive) throws -> T) throws -> T {
        let archive = try InputArchive(path: path)
        return try body(archive)
    }

    /// Async variant — lets callers schedule archive writes from async contexts.
    @discardableResult
    public static func withArchive<T: Sendable>(path: String, _ body: @Sendable (Archive) throws -> T) async throws -> T {
        let archive = try Archive(path: path)
        return try body(archive)
    }
}

// MARK: - Sample iteration (D3 / D13)

extension Alembic {
    /// Implemented by every Reader type; enables the generic `.samples` AsyncSequence.
    public protocol SampledReader<Sample>: AnyObject {
        associatedtype Sample
        var sampleCount: Int { get }
        func sample(at idx: Int) throws -> Sample
    }

    /// Lazy async sequence over all samples in a reader — use `for try await` to iterate.
    public struct SampleSequence<R: SampledReader>: AsyncSequence {
        public typealias Element = R.Sample
        private let reader: R
        init(_ reader: R) { self.reader = reader }
        public func makeAsyncIterator() -> AsyncIterator { AsyncIterator(reader) }
        public struct AsyncIterator: AsyncIteratorProtocol {
            private let reader: R
            private var index = 0
            init(_ reader: R) { self.reader = reader }
            public mutating func next() async throws -> R.Sample? {
                guard index < reader.sampleCount else { return nil }
                defer { index += 1 }
                return try reader.sample(at: index)
            }
        }
    }
}

extension Alembic.SampledReader {
    public var samples: Alembic.SampleSequence<Self> { .init(self) }
}

extension Alembic.PolyMeshReader: Alembic.SampledReader {}
extension Alembic.SubDReader: Alembic.SampledReader {}
extension Alembic.CurvesReader: Alembic.SampledReader {}
extension Alembic.PointsReader: Alembic.SampledReader {}
extension Alembic.NuPatchReader: Alembic.SampledReader {}
extension Alembic.XformReader: Alembic.SampledReader {}
extension Alembic.CameraReader: Alembic.SampledReader {}
extension Alembic.LightReader: Alembic.SampledReader {}
extension Alembic.FaceSetReader: Alembic.SampledReader {}

// MARK: - Back-compat typealiases (ease migration; remove in next major version)

@available(*, deprecated, renamed: "Alembic.Archive")
public typealias AlembicArchive = Alembic.Archive
@available(*, deprecated, renamed: "Alembic.InputArchive")
public typealias AlembicInputArchive = Alembic.InputArchive
@available(*, deprecated, renamed: "Alembic.Object")
public typealias AlembicObject = Alembic.Object
@available(*, deprecated, renamed: "Alembic.InputObject")
public typealias AlembicInputObject = Alembic.InputObject
@available(*, deprecated, renamed: "Alembic.Error")
public typealias AlembicError = Alembic.Error
@available(*, deprecated, renamed: "Alembic.SchemaType")
public typealias AlembicSchemaType = Alembic.SchemaType
