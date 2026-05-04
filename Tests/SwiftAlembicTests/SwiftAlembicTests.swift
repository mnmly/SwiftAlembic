import Testing
import Foundation
import SwiftAlembic
import CAlembic
import simd

// MARK: - PolyMesh round-trip

@Test func polyMeshRoundTrip_positionsAndFaces() throws {
    let tmpPath = "/tmp/test_alembic_\(UUID().uuidString).abc"
    defer { try? FileManager.default.removeItem(atPath: tmpPath) }

    do {
        let archive = try Alembic.Archive(path: tmpPath)
        let meshObj = archive.top.createChild(name: "mesh1")
        var sample = Alembic.PolyMeshSample()
        sample.positions = [
            SIMD3<Float>(0, 0, 0), SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(1, 1, 0), SIMD3<Float>(0, 1, 0),
        ]
        sample.faceCounts = [4]
        sample.faceIndices = [0, 1, 2, 3]
        try meshObj.addPolyMesh(name: "polyMesh1").set(sample)
    }

    let input = try Alembic.InputArchive(path: tmpPath)
    let schema = input.top.children[0].children[0]
    let reader = try #require(schema.asPolyMesh())
    #expect(reader.sampleCount == 1)

    let s = try reader.sample(at: 0)
    #expect(s.positions.count == 4)
    #expect(s.positions[0] == SIMD3<Float>(0, 0, 0))
    #expect(s.positions[1] == SIMD3<Float>(1, 0, 0))
    #expect(s.faceCounts == [4])
    #expect(s.faceIndices == [0, 1, 2, 3])
}

@Test func polyMeshRoundTrip_withNormalsAndUVs() throws {
    let tmpPath = "/tmp/test_alembic_\(UUID().uuidString).abc"
    defer { try? FileManager.default.removeItem(atPath: tmpPath) }

    do {
        let archive = try Alembic.Archive(path: tmpPath)
        let meshObj = archive.top.createChild(name: "mesh1")
        var sample = Alembic.PolyMeshSample()
        sample.positions = [
            SIMD3<Float>(0, 0, 0), SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(1, 1, 0), SIMD3<Float>(0, 1, 0),
        ]
        sample.faceCounts = [4]
        sample.faceIndices = [0, 1, 2, 3]
        sample.normals = [
            SIMD3<Float>(0, 0, 1), SIMD3<Float>(0, 0, 1),
            SIMD3<Float>(0, 0, 1), SIMD3<Float>(0, 0, 1),
        ]
        sample.uvs = [
            SIMD2<Float>(0, 0), SIMD2<Float>(1, 0),
            SIMD2<Float>(1, 1), SIMD2<Float>(0, 1),
        ]
        try meshObj.addPolyMesh(name: "polyMesh1").set(sample)
    }

    let input = try Alembic.InputArchive(path: tmpPath)
    let schema = input.top.children[0].children[0]
    let reader = try #require(schema.asPolyMesh())
    let s = try reader.sample(at: 0)
    #expect(s.normals != nil)
    #expect(s.normals!.count == 4)
    #expect(s.uvs != nil)
    #expect(s.uvs!.count == 4)
}

// MARK: - Points round-trip

@Test func pointsRoundTrip() throws {
    let tmpPath = "/tmp/test_alembic_\(UUID().uuidString).abc"
    defer { try? FileManager.default.removeItem(atPath: tmpPath) }

    do {
        let archive = try Alembic.Archive(path: tmpPath)
        let pointsObj = archive.top.createChild(name: "points1")
        var sample = Alembic.PointsSample()
        sample.positions = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 2, 3),
            SIMD3<Float>(4, 5, 6),
        ]
        try pointsObj.addPoints(name: "points").set(sample)
    }

    let input = try Alembic.InputArchive(path: tmpPath)
    let reader = try #require(input.top.children[0].children[0].asPoints())
    #expect(reader.sampleCount == 1)

    let s = try reader.sample(at: 0)
    #expect(s.positions.count == 3)
    #expect(s.positions[0] == SIMD3<Float>(0, 0, 0))
    #expect(s.positions[1] == SIMD3<Float>(1, 2, 3))
    #expect(s.positions[2] == SIMD3<Float>(4, 5, 6))
}

// MARK: - Curves round-trip

@Test func curvesRoundTrip() throws {
    let tmpPath = "/tmp/test_alembic_\(UUID().uuidString).abc"
    defer { try? FileManager.default.removeItem(atPath: tmpPath) }

    do {
        let archive = try Alembic.Archive(path: tmpPath)
        let curvesObj = archive.top.createChild(name: "curves1")
        var sample = Alembic.CurvesSample()
        sample.positions = [
            SIMD3<Float>(0, 0, 0), SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(2, 1, 0), SIMD3<Float>(3, 2, 0),
        ]
        sample.vertsPerCurve = [4]
        try curvesObj.addCurves(name: "curves").set(sample)
    }

    let input = try Alembic.InputArchive(path: tmpPath)
    let reader = try #require(input.top.children[0].children[0].asCurves())
    #expect(reader.sampleCount == 1)

    let s = try reader.sample(at: 0)
    #expect(s.positions.count == 4)
    #expect(s.vertsPerCurve == [4])
}

// MARK: - Xform round-trip

@Test func xformRoundTrip_translate() throws {
    let tmpPath = "/tmp/test_alembic_\(UUID().uuidString).abc"
    defer { try? FileManager.default.removeItem(atPath: tmpPath) }

    do {
        let archive = try Alembic.Archive(path: tmpPath)
        let xformObj = archive.top.createChild(name: "xform1")
        var xformSample = Alembic.XformSample()
        xformSample.ops = [Alembic.XformOp(type: .translate, values: [1.0, 2.0, 3.0])]
        try xformObj.addXform(name: "xform").set(xformSample)
    }

    let input = try Alembic.InputArchive(path: tmpPath)
    let reader = try #require(input.top.children[0].children[0].asXform())
    #expect(reader.sampleCount == 1)

    let s = try reader.sample(at: 0)
    #expect(s.ops.count == 1)
    #expect(s.ops[0].type == .translate)
    #expect(s.ops[0].values == [1.0, 2.0, 3.0])
}

@Test func xformRoundTrip_rotate() throws {
    let tmpPath = "/tmp/test_alembic_\(UUID().uuidString).abc"
    defer { try? FileManager.default.removeItem(atPath: tmpPath) }

    do {
        let archive = try Alembic.Archive(path: tmpPath)
        let xformObj = archive.top.createChild(name: "xform1")
        var xformSample = Alembic.XformSample()
        xformSample.ops = [Alembic.XformOp(type: .rotate, values: [0.0, 0.0, 1.0, 90.0])]
        try xformObj.addXform(name: "xform").set(xformSample)
    }

    let input = try Alembic.InputArchive(path: tmpPath)
    let reader = try #require(input.top.children[0].children[0].asXform())
    let s = try reader.sample(at: 0)
    #expect(s.ops[0].type == .rotate)
    #expect(s.ops[0].values[0] == 0.0 && s.ops[0].values[1] == 0.0)
    #expect(s.ops[0].values[2] == 1.0 && s.ops[0].values[3] == 90.0)
}

@Test func xformRoundTrip_scale() throws {
    let tmpPath = "/tmp/test_alembic_\(UUID().uuidString).abc"
    defer { try? FileManager.default.removeItem(atPath: tmpPath) }

    do {
        let archive = try Alembic.Archive(path: tmpPath)
        let xformObj = archive.top.createChild(name: "xform1")
        var xformSample = Alembic.XformSample()
        xformSample.ops = [Alembic.XformOp(type: .scale, values: [2.0, 2.0, 2.0])]
        try xformObj.addXform(name: "xform").set(xformSample)
    }

    let input = try Alembic.InputArchive(path: tmpPath)
    let reader = try #require(input.top.children[0].children[0].asXform())
    let s = try reader.sample(at: 0)
    #expect(s.ops[0].type == .scale)
    #expect(s.ops[0].values == [2.0, 2.0, 2.0])
}

@Test func xformRoundTrip_inherits() throws {
    let tmpPath = "/tmp/test_alembic_\(UUID().uuidString).abc"
    defer { try? FileManager.default.removeItem(atPath: tmpPath) }

    do {
        let archive = try Alembic.Archive(path: tmpPath)
        let xformObj = archive.top.createChild(name: "xform1")
        var xformSample = Alembic.XformSample()
        xformSample.inherits = false
        xformSample.ops = [Alembic.XformOp(type: .translate, values: [5.0, 0.0, 0.0])]
        try xformObj.addXform(name: "xform").set(xformSample)
    }

    let input = try Alembic.InputArchive(path: tmpPath)
    let reader = try #require(input.top.children[0].children[0].asXform())
    let s = try reader.sample(at: 0)
    #expect(s.inherits == false)
    #expect(s.ops[0].values == [5.0, 0.0, 0.0])
}

// MARK: - Camera round-trip

@Test func cameraRoundTrip_focalLength() throws {
    let tmpPath = "/tmp/test_alembic_\(UUID().uuidString).abc"
    defer { try? FileManager.default.removeItem(atPath: tmpPath) }

    do {
        let archive = try Alembic.Archive(path: tmpPath)
        let camObj = archive.top.createChild(name: "camera1")
        var camSample = Alembic.CameraSample()
        camSample.focalLength = 50.0
        try camObj.addCamera(name: "camera").set(camSample)
    }

    let input = try Alembic.InputArchive(path: tmpPath)
    let reader = try #require(input.top.children[0].children[0].asCamera())
    #expect(reader.sampleCount == 1)

    let s = try reader.sample(at: 0)
    #expect(s.focalLength == 50.0)
}

// MARK: - SubD round-trip

@Test func subDRoundTrip() throws {
    let tmpPath = "/tmp/test_alembic_\(UUID().uuidString).abc"
    defer { try? FileManager.default.removeItem(atPath: tmpPath) }

    do {
        let archive = try Alembic.Archive(path: tmpPath)
        let subdObj = archive.top.createChild(name: "subd1")
        var sample = Alembic.SubDSample()
        sample.positions = [
            SIMD3<Float>(0, 0, 0), SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(1, 1, 0), SIMD3<Float>(0, 1, 0),
        ]
        sample.faceCounts = [4]
        sample.faceIndices = [0, 1, 2, 3]
        try subdObj.addSubD(name: "subd").set(sample)
    }

    let input = try Alembic.InputArchive(path: tmpPath)
    let reader = try #require(input.top.children[0].children[0].asSubD())
    #expect(reader.sampleCount == 1)

    let s = try reader.sample(at: 0)
    #expect(s.positions.count == 4)
    #expect(s.faceCounts == [4])
    #expect(s.faceIndices == [0, 1, 2, 3])
}

// MARK: - FaceSet round-trip

@Test func faceSetRoundTrip() throws {
    let tmpPath = "/tmp/test_alembic_\(UUID().uuidString).abc"
    defer { try? FileManager.default.removeItem(atPath: tmpPath) }

    do {
        let archive = try Alembic.Archive(path: tmpPath)
        let obj = archive.top.createChild(name: "fs1")
        var sample = Alembic.FaceSetSample()
        sample.faceIndices = [0, 2, 4, 6]
        try obj.addFaceSet(name: "faceset").set(sample)
    }

    let input = try Alembic.InputArchive(path: tmpPath)
    let reader = try #require(input.top.children[0].children[0].asFaceSet())
    #expect(reader.sampleCount == 1)

    let s = try reader.sample(at: 0)
    #expect(s.faceIndices == [0, 2, 4, 6])
}

// MARK: - Light round-trip

@Test func lightRoundTrip_sampleCount() throws {
    let tmpPath = "/tmp/test_alembic_\(UUID().uuidString).abc"
    defer { try? FileManager.default.removeItem(atPath: tmpPath) }

    do {
        let archive = try Alembic.Archive(path: tmpPath)
        let lightObj = archive.top.createChild(name: "light1")
        try lightObj.addLight(name: "light").set(Alembic.LightSample())
    }

    let input = try Alembic.InputArchive(path: tmpPath)
    let reader = try #require(input.top.children[0].children[0].asLight())
    #expect(reader.sampleCount > 0)
}

// MARK: - Schema type query

@Test func schemaTypeQuery() throws {
    let tmpPath = "/tmp/test_alembic_\(UUID().uuidString).abc"
    defer { try? FileManager.default.removeItem(atPath: tmpPath) }

    do {
        let archive = try Alembic.Archive(path: tmpPath)
        let obj = archive.top.createChild(name: "mesh1")
        var sample = Alembic.PolyMeshSample()
        sample.positions = [SIMD3<Float>(0, 0, 0), SIMD3<Float>(1, 0, 0), SIMD3<Float>(1, 1, 0)]
        sample.faceCounts = [3]
        sample.faceIndices = [0, 1, 2]
        try obj.addPolyMesh(name: "mesh").set(sample)
    }

    let input = try Alembic.InputArchive(path: tmpPath)
    let obj = input.top.children[0]
    #expect(obj.schemaType == .unknown)

    let schema = obj.children[0]
    #expect(schema.schemaType == .polyMesh)
    #expect(schema.name == "mesh")
}
