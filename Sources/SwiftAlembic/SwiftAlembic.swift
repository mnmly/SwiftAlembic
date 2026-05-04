import CAlembic
import CxxStdlib

// MARK: - Error

public enum AlembicError: Error, CustomStringConvertible {
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
    static func fromLast() -> AlembicError {
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

// MARK: - Types

public struct AlembicV2f: Sendable { public var x, y: Float; public init(x: Float, y: Float) { self.x = x; self.y = y } }
public struct AlembicV3f: Sendable { public var x, y, z: Float; public init(x: Float, y: Float, z: Float) { self.x = x; self.y = y; self.z = z } }
public struct AlembicV3d: Sendable { public var x, y, z: Double; public init(x: Double, y: Double, z: Double) { self.x = x; self.y = y; self.z = z } }
public struct AlembicN3f: Sendable { public var x, y, z: Float; public init(x: Float, y: Float, z: Float) { self.x = x; self.y = y; self.z = z } }
public struct AlembicBox3d: Sendable { public var min, max: AlembicV3d; public init(min: AlembicV3d, max: AlembicV3d) { self.min = min; self.max = max } }

extension AlembicV3f { init(_ c: CAlembicV3f) { self.init(x: c.x, y: c.y, z: c.z) }; var cxx: CAlembicV3f { CAlembicV3f(x: x, y: y, z: z) } }
extension AlembicV3d { init(_ c: CAlembicV3d) { self.init(x: c.x, y: c.y, z: c.z) }; var cxx: CAlembicV3d { CAlembicV3d(x: x, y: y, z: z) } }
extension AlembicN3f { init(_ c: CAlembicN3f) { self.init(x: c.x, y: c.y, z: c.z) }; var cxx: CAlembicN3f { CAlembicN3f(x: x, y: y, z: z) } }
extension AlembicV2f { init(_ c: CAlembicV2f) { self.init(x: c.x, y: c.y) }; var cxx: CAlembicV2f { CAlembicV2f(x: x, y: y) } }
extension AlembicBox3d { init(_ c: CAlembicBox3d) { self.init(min: AlembicV3d(c.min), max: AlembicV3d(c.max)) }; var cxx: CAlembicBox3d { CAlembicBox3d(min: min.cxx, max: max.cxx) } }

// MARK: - Archive + Object

public final class AlembicObject {
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
    @discardableResult public func createChild(name: String) -> AlembicObject { .init(ptr: calembic_create_child(ptr, std.string(name))) }
}

public final class AlembicInputObject {
    public let ptr: AlembicIObjectPtr
    public init(ptr: AlembicIObjectPtr) { self.ptr = ptr }
    public var name: String { String(calembic_object_name(ptr)) }
    public var fullName: String { String(calembic_object_full_name(ptr)) }
    public var children: [AlembicInputObject] {
        let v = calembic_object_children(ptr); var r: [AlembicInputObject] = []
        for i in 0..<v.size() { r.append(.init(ptr: v[i])) }; return r
    }
}

public struct AlembicArchive {
    public let handle: AlembicOArchivePtr
    public init(path: String) throws {
        handle = calembic_create_archive(std.string(path))
        if calembic_last_error_code() != CAlembicError_OK { throw AlembicError.fromLast() }
    }
    public var top: AlembicObject { .init(ptr: calembic_archive_top_O(handle)) }
}

public struct AlembicInputArchive {
    public let handle: AlembicIArchivePtr
    public init(path: String) throws {
        handle = calembic_open_archive(std.string(path))
        if calembic_last_error_code() != CAlembicError_OK { throw AlembicError.fromLast() }
    }
    public var top: AlembicInputObject { .init(ptr: calembic_archive_top_I(handle)) }
}

// MARK: - PolyMesh

public struct PolyMeshSample: Sendable {
    public var positions: [AlembicV3f] = []; public var faceIndices: [Int32] = []; public var faceCounts: [Int32] = []
    public var normals: [AlembicN3f]?; public var uvs: [AlembicV2f]?; public var velocities: [AlembicV3f]?; public var selfBounds: AlembicBox3d?
    public init() {}
}

public final class PolyMeshWriter {
    let ptr: AlembicOPolyMeshPtr; init(ptr: AlembicOPolyMeshPtr) { self.ptr = ptr }
    @discardableResult public func set(_ s: PolyMeshSample) throws -> Self {
        var c = CAlembicPolyMeshSample()
        for p in s.positions { c.positions.push_back(p.cxx) }
        for v in s.faceIndices { c.faceIndices.push_back(v) }
        for v in s.faceCounts { c.faceCounts.push_back(v) }
        if let n = s.normals { for v in n { c.normals.push_back(v.cxx) }; c.hasNormals = true }
        if let u = s.uvs { for v in u { c.uvs.push_back(v.cxx) }; c.hasUVs = true }
        if let v = s.velocities { for v2 in v { c.velocities.push_back(v2.cxx) }; c.hasVelocities = true }
        if let b = s.selfBounds { c.selfBounds = b.cxx; c.selfBoundsSet = true }
        try AlembicError.check(calembic_polymesh_set(ptr, c)); return self
    }
}

public final class PolyMeshReader {
    let ptr: AlembicIPolyMeshPtr; init(ptr: AlembicIPolyMeshPtr) { self.ptr = ptr }
    public var sampleCount: Int { Int(calembic_polymesh_num_samples(ptr)) }
    public func sample(at idx: Int) throws -> PolyMeshSample {
        var c = CAlembicPolyMeshSample()
        let code = calembic_polymesh_get(ptr, UInt32(idx), &c)
        if code != 0 { throw AlembicError.fromLast() }
        var s = PolyMeshSample()
        for i in 0..<c.positions.size() { s.positions.append(AlembicV3f(c.positions[i])) }
        for i in 0..<c.faceIndices.size() { s.faceIndices.append(c.faceIndices[i]) }
        for i in 0..<c.faceCounts.size() { s.faceCounts.append(c.faceCounts[i]) }
        if c.hasNormals { var n: [AlembicN3f] = []; for i in 0..<c.normals.size() { n.append(AlembicN3f(c.normals[i])) }; s.normals = n }
        if c.hasUVs { var u: [AlembicV2f] = []; for i in 0..<c.uvs.size() { u.append(AlembicV2f(c.uvs[i])) }; s.uvs = u }
        if c.hasVelocities { var v: [AlembicV3f] = []; for i in 0..<c.velocities.size() { v.append(AlembicV3f(c.velocities[i])) }; s.velocities = v }
        if c.selfBoundsSet { s.selfBounds = AlembicBox3d(c.selfBounds) }
        return s
    }
}

// MARK: - Xform

public enum XformOpType: Sendable { case translate, rotate, scale, matrix
    var cxx: CAlembicXformOpType {
        switch self { case .translate: CAlembicXformOp_Translate; case .rotate: CAlembicXformOp_Rotate; case .scale: CAlembicXformOp_Scale; case .matrix: CAlembicXformOp_Matrix }
    }
}
public struct XformOp: Sendable { public var type: XformOpType; public var values: [Double]; public init(type: XformOpType, values: [Double]) { self.type = type; self.values = values } }
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
        try AlembicError.check(calembic_xform_set(ptr, c)); return self
    }
}

public final class XformReader {
    let ptr: AlembicIXformPtr; init(ptr: AlembicIXformPtr) { self.ptr = ptr }
    public var sampleCount: Int { Int(calembic_xform_num_samples(ptr)) }
    public func sample(at idx: Int) throws -> XformSample {
        var c = CAlembicXformSample()
        let code = calembic_xform_get(ptr, UInt32(idx), &c)
        if code != 0 { throw AlembicError.fromLast() }
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

// MARK: - Simplified schemas: SubD, Curves, Points, NuPatch, Camera, Light, FaceSet

public struct SubDSample: Sendable { public var positions: [AlembicV3f] = []; public var faceIndices: [Int32] = []; public var faceCounts: [Int32] = []; public init() {} }
public final class SubDWriter { let ptr: AlembicOSubDPtr; init(ptr: AlembicOSubDPtr) { self.ptr = ptr }
    @discardableResult public func set(_ s: SubDSample) throws -> Self {
        var c = CAlembicSubDSample(); for p in s.positions { c.positions.push_back(p.cxx) }; for v in s.faceIndices { c.faceIndices.push_back(v) }; for v in s.faceCounts { c.faceCounts.push_back(v) }
        try AlembicError.check(calembic_subd_set(ptr, c)); return self
    }
}
public final class SubDReader { let ptr: AlembicISubDPtr; init(ptr: AlembicISubDPtr) { self.ptr = ptr }
    public var sampleCount: Int { Int(calembic_subd_num_samples(ptr)) }
    public func sample(at idx: Int) throws -> SubDSample {
        var c = CAlembicSubDSample(); try AlembicError.check(calembic_subd_get(ptr, UInt32(idx), &c))
        var s = SubDSample(); for i in 0..<c.positions.size() { s.positions.append(AlembicV3f(c.positions[i])) }; for i in 0..<c.faceIndices.size() { s.faceIndices.append(c.faceIndices[i]) }; for i in 0..<c.faceCounts.size() { s.faceCounts.append(c.faceCounts[i]) }; return s
    }
}

public struct CurvesSample: Sendable { public var positions: [AlembicV3f] = []; public var vertsPerCurve: [Int32] = []; public init() {} }
public final class CurvesWriter { let ptr: AlembicOCurvesPtr; init(ptr: AlembicOCurvesPtr) { self.ptr = ptr }
    @discardableResult public func set(_ s: CurvesSample) throws -> Self {
        var c = CAlembicCurvesSample(); for p in s.positions { c.positions.push_back(p.cxx) }; for v in s.vertsPerCurve { c.vertsPerCurve.push_back(v) }
        try AlembicError.check(calembic_curves_set(ptr, c)); return self
    }
}
public final class CurvesReader { let ptr: AlembicICurvesPtr; init(ptr: AlembicICurvesPtr) { self.ptr = ptr }
    public var sampleCount: Int { Int(calembic_curves_num_samples(ptr)) }
    public func sample(at idx: Int) throws -> CurvesSample {
        var c = CAlembicCurvesSample(); try AlembicError.check(calembic_curves_get(ptr, UInt32(idx), &c))
        var s = CurvesSample(); for i in 0..<c.positions.size() { s.positions.append(AlembicV3f(c.positions[i])) }; for i in 0..<c.vertsPerCurve.size() { s.vertsPerCurve.append(c.vertsPerCurve[i]) }; return s
    }
}

public struct PointsSample: Sendable { public var positions: [AlembicV3f] = []; public init() {} }
public final class PointsWriter { let ptr: AlembicOPointsPtr; init(ptr: AlembicOPointsPtr) { self.ptr = ptr }
    @discardableResult public func set(_ s: PointsSample) throws -> Self {
        var c = CAlembicPointsSample(); for p in s.positions { c.positions.push_back(p.cxx) }
        try AlembicError.check(calembic_points_set(ptr, c)); return self
    }
}
public final class PointsReader { let ptr: AlembicIPointsPtr; init(ptr: AlembicIPointsPtr) { self.ptr = ptr }
    public var sampleCount: Int { Int(calembic_points_num_samples(ptr)) }
    public func sample(at idx: Int) throws -> PointsSample {
        var c = CAlembicPointsSample(); try AlembicError.check(calembic_points_get(ptr, UInt32(idx), &c))
        var s = PointsSample(); for i in 0..<c.positions.size() { s.positions.append(AlembicV3f(c.positions[i])) }; return s
    }
}

public struct NuPatchSample: Sendable { public var positions: [AlembicV3f] = []; public init() {} }
public final class NuPatchWriter { let ptr: AlembicONuPatchPtr; init(ptr: AlembicONuPatchPtr) { self.ptr = ptr }
    @discardableResult public func set(_ s: NuPatchSample) throws -> Self {
        var c = CAlembicNuPatchSample(); for p in s.positions { c.positions.push_back(p.cxx) }
        try AlembicError.check(calembic_nupatch_set(ptr, c)); return self
    }
}
public final class NuPatchReader { let ptr: AlembicINuPatchPtr; init(ptr: AlembicINuPatchPtr) { self.ptr = ptr }
    public var sampleCount: Int { Int(calembic_nupatch_num_samples(ptr)) }
    public func sample(at idx: Int) throws -> NuPatchSample {
        var c = CAlembicNuPatchSample(); try AlembicError.check(calembic_nupatch_get(ptr, UInt32(idx), &c))
        var s = NuPatchSample(); for i in 0..<c.positions.size() { s.positions.append(AlembicV3f(c.positions[i])) }; return s
    }
}

public struct CameraSample: Sendable { public var focalLength: Double = 35; public init() {} }
public final class CameraWriter { let ptr: AlembicOCameraPtr; init(ptr: AlembicOCameraPtr) { self.ptr = ptr }
    @discardableResult public func set(_ s: CameraSample) throws -> Self {
        var c = CAlembicCameraSample(); c.focalLength = s.focalLength
        try AlembicError.check(calembic_camera_set(ptr, c)); return self
    }
}
public final class CameraReader { let ptr: AlembicICameraPtr; init(ptr: AlembicICameraPtr) { self.ptr = ptr }
    public var sampleCount: Int { Int(calembic_camera_num_samples(ptr)) }
    public func sample(at idx: Int) throws -> CameraSample {
        var c = CAlembicCameraSample(); try AlembicError.check(calembic_camera_get(ptr, UInt32(idx), &c))
        var s = CameraSample(); s.focalLength = c.focalLength; return s
    }
}

public struct LightSample: Sendable { public init() {} }
public final class LightWriter { let ptr: AlembicOLightPtr; init(ptr: AlembicOLightPtr) { self.ptr = ptr }
    @discardableResult public func set(_: LightSample) throws -> Self {
        var c = CAlembicLightSample(); try AlembicError.check(calembic_light_set(ptr, c)); return self
    }
}
public final class LightReader { let ptr: AlembicILightPtr; init(ptr: AlembicILightPtr) { self.ptr = ptr }
    public var sampleCount: Int { Int(calembic_light_num_samples(ptr)) }
    public func sample(at idx: Int) throws -> LightSample {
        var c = CAlembicLightSample(); try AlembicError.check(calembic_light_get(ptr, UInt32(idx), &c))
        return LightSample()
    }
}

public struct FaceSetSample: Sendable { public var faceIndices: [Int32] = []; public init() {} }
public final class FaceSetWriter { let ptr: AlembicOFaceSetPtr; init(ptr: AlembicOFaceSetPtr) { self.ptr = ptr }
    @discardableResult public func set(_ s: FaceSetSample) throws -> Self {
        var c = CAlembicFaceSetSample(); for v in s.faceIndices { c.faceIndices.push_back(v) }
        try AlembicError.check(calembic_faceset_set(ptr, c)); return self
    }
}
public final class FaceSetReader { let ptr: AlembicIFaceSetPtr; init(ptr: AlembicIFaceSetPtr) { self.ptr = ptr }
    public var sampleCount: Int { Int(calembic_faceset_num_samples(ptr)) }
    public func sample(at idx: Int) throws -> FaceSetSample {
        var c = CAlembicFaceSetSample(); try AlembicError.check(calembic_faceset_get(ptr, UInt32(idx), &c))
        var s = FaceSetSample(); for i in 0..<c.faceIndices.size() { s.faceIndices.append(c.faceIndices[i]) }; return s
    }
}
