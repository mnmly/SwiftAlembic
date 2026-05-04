import Testing
import Foundation
import SwiftAlembic

@Test func writePolyMeshAndReadBack() throws {
    let tmpPath = "/tmp/test_alembic_\(UUID().uuidString).abc"
    defer { try? FileManager.default.removeItem(atPath: tmpPath) }

    do {
        let archive = try AlembicArchive(path: tmpPath)
        let meshObj = archive.top.createChild(name: "mesh1")
        var sample = PolyMeshSample()
        sample.positions = [
            AlembicV3f(x: 0, y: 0, z: 0), AlembicV3f(x: 1, y: 0, z: 0),
            AlembicV3f(x: 1, y: 1, z: 0), AlembicV3f(x: 0, y: 1, z: 0),
        ]
        sample.faceCounts = [4]
        sample.faceIndices = [0, 1, 2, 3]
        try meshObj.addPolyMesh(name: "polyMesh1").set(sample)
    }

    let input = try AlembicInputArchive(path: tmpPath)
    let top = input.top
    #expect(!top.children.isEmpty)
    #expect(top.children[0].name == "mesh1")
    #expect(!top.children[0].children.isEmpty)
    #expect(top.children[0].children[0].name == "polyMesh1")
}

@Test func writeXform() throws {
    let tmpPath = "/tmp/test_xform_\(UUID().uuidString).abc"
    defer { try? FileManager.default.removeItem(atPath: tmpPath) }

    do {
        let archive = try AlembicArchive(path: tmpPath)
        let xformObj = archive.top.createChild(name: "xform1")
        var xformSample = XformSample()
        xformSample.ops = [XformOp(type: .translate, values: [1.0, 2.0, 3.0])]
        try xformObj.addXform(name: "xform").set(xformSample)
    }

    let input = try AlembicInputArchive(path: tmpPath)
    #expect(!input.top.children.isEmpty)
    #expect(input.top.children[0].name == "xform1")
}

@Test func writePointsAndReadBack() throws {
    let tmpPath = "/tmp/test_points_\(UUID().uuidString).abc"
    defer { try? FileManager.default.removeItem(atPath: tmpPath) }

    do {
        let archive = try AlembicArchive(path: tmpPath)
        let pointsObj = archive.top.createChild(name: "points1")
        var sample = PointsSample()
        sample.positions = [
            AlembicV3f(x: 0, y: 0, z: 0),
            AlembicV3f(x: 1, y: 2, z: 3),
            AlembicV3f(x: 4, y: 5, z: 6),
        ]
        try pointsObj.addPoints(name: "points").set(sample)
    }

    let input = try AlembicInputArchive(path: tmpPath)
    #expect(input.top.children.first?.name == "points1")
}

@Test func writeCurves() throws {
    let tmpPath = "/tmp/test_curves_\(UUID().uuidString).abc"
    defer { try? FileManager.default.removeItem(atPath: tmpPath) }

    do {
        let archive = try AlembicArchive(path: tmpPath)
        let curvesObj = archive.top.createChild(name: "curves1")
        var sample = CurvesSample()
        sample.positions = [
            AlembicV3f(x: 0, y: 0, z: 0), AlembicV3f(x: 1, y: 0, z: 0),
            AlembicV3f(x: 2, y: 1, z: 0), AlembicV3f(x: 3, y: 2, z: 0),
        ]
        sample.vertsPerCurve = [4]
        try curvesObj.addCurves(name: "curves").set(sample)
    }

    let input = try AlembicInputArchive(path: tmpPath)
    #expect(input.top.children.first?.name == "curves1")
}
