// PointCloudAnimation.swift
//
// Demonstrates writing and reading a multi-frame animated point cloud with SwiftAlembic.
//
// The scene contains three layers of particles:
//   • An inner shell of tightly orbiting points
//   • A mid-ring of slowly drifting points
//   • An outer sparse cloud of near-stationary points
//
// Run:  swift run Examples [output.abc]

import Foundation
import SwiftAlembic
import simd

// MARK: - Particle simulation

struct Particle {
    var position: SIMD3<Float>
    var velocity: SIMD3<Float>
    var phase: Float         // per-particle phase offset for wave motion
    var orbitRadius: Float
    var orbitSpeed: Float
    var layer: Int
}

func generateParticles(count: Int, seed: UInt64 = 42) -> [Particle] {
    var rng = SeededRandom(seed: seed)
    return (0..<count).map { i in
        let layer = i % 3
        let r: Float = layer == 0 ? rng.float(1.0, 3.0)
                     : layer == 1 ? rng.float(4.0, 7.0)
                     : rng.float(8.0, 14.0)
        let theta = rng.float(0, .pi * 2)
        let phi   = rng.float(-.pi / 2, .pi / 2)
        let x = r * cos(phi) * cos(theta)
        let y = r * sin(phi)
        let z = r * cos(phi) * sin(theta)
        let speed: Float = layer == 0 ? rng.float(0.8, 1.6)
                         : layer == 1 ? rng.float(0.3, 0.7)
                         : rng.float(0.02, 0.1)
        return Particle(
            position: SIMD3(x, y, z),
            velocity: SIMD3(rng.float(-0.02, 0.02), rng.float(-0.01, 0.01), rng.float(-0.02, 0.02)),
            phase: rng.float(0, .pi * 2),
            orbitRadius: r,
            orbitSpeed: speed,
            layer: layer
        )
    }
}

func advanceParticles(_ particles: inout [Particle], frame: Int, fps: Float) {
    let t = Float(frame) / fps
    for i in particles.indices {
        let p = particles[i]
        // Orbit in XZ, breathing in Y
        let angle = t * p.orbitSpeed + p.phase
        let breathe = sin(t * 0.7 + p.phase) * 0.4
        let xz = normalize(SIMD2(p.position.x, p.position.z)) * p.orbitRadius
        particles[i].position = SIMD3(
            xz.x * cos(angle * 0.1) - xz.y * sin(angle * 0.1),
            p.position.y + breathe * 0.01,
            xz.x * sin(angle * 0.1) + xz.y * cos(angle * 0.1)
        )
        // Outer layer drifts freely
        if p.layer == 2 {
            particles[i].position += p.velocity
        }
    }
}

func positions(of particles: [Particle]) -> [SIMD3<Float>] {
    particles.map(\.position)
}

// MARK: - Write

func writeAnimation(to path: String, particleCount: Int, frameCount: Int, fps: Float) throws {
    print("Writing \(frameCount) frames, \(particleCount) particles → \(path)")

    try Alembic.withArchive(path: path) { archive in
        let pointsObj = archive.top.createChild(name: "particleCloud")
        let writer = pointsObj.addPoints(name: "points")

        var particles = generateParticles(count: particleCount)

        for frame in 0..<frameCount {
            advanceParticles(&particles, frame: frame, fps: fps)
            var sample = Alembic.PointsSample()
            sample.positions = positions(of: particles)
            try writer.set(sample)

            if frame % 12 == 0 {
                let pct = Int(Double(frame) / Double(frameCount) * 100)
                print("  [\(String(format: "%3d", pct))%] frame \(frame)/\(frameCount)")
            }
        }
    }

    print("Write complete.")
}

// MARK: - Read (async iteration via .samples)

func readAnimation(from path: String) async throws {
    print("\nReading \(path) …")

    let archive = try Alembic.InputArchive(path: path)
    let cloudObj = archive.top.children[0]       // particleCloud
    let schemaObj = cloudObj.children[0]          // points

    guard let reader = schemaObj.asPoints() else {
        print("No points schema found.")
        return
    }

    print("Found \(reader.sampleCount) frames.")

    var frameIndex = 0
    var totalPoints = 0
    var globalMin = SIMD3<Float>(repeating: .greatestFiniteMagnitude)
    var globalMax = SIMD3<Float>(repeating: -.greatestFiniteMagnitude)

    for try await sample in reader.samples {
        totalPoints += sample.positions.count
        for p in sample.positions {
            globalMin = min(globalMin, p)
            globalMax = max(globalMax, p)
        }

        if frameIndex % 12 == 0 {
            let localMin = sample.positions.reduce(SIMD3<Float>(repeating:  .greatestFiniteMagnitude)) { min($0, $1) }
            let localMax = sample.positions.reduce(SIMD3<Float>(repeating: -.greatestFiniteMagnitude)) { max($0, $1) }
            print(String(format: "  frame %3d  pts=%d  bbox=(%.2f,%.2f,%.2f)→(%.2f,%.2f,%.2f)",
                frameIndex, sample.positions.count,
                localMin.x, localMin.y, localMin.z,
                localMax.x, localMax.y, localMax.z))
        }
        frameIndex += 1
    }

    print("\nSummary:")
    print("  Frames read  : \(frameIndex)")
    print("  Total points : \(totalPoints)")
    print(String(format: "  Global bbox  : (%.2f,%.2f,%.2f) → (%.2f,%.2f,%.2f)",
        globalMin.x, globalMin.y, globalMin.z,
        globalMax.x, globalMax.y, globalMax.z))
}

// MARK: - Entry point

@main struct PointCloudAnimation {
    static func main() async {
        let outputPath = CommandLine.arguments.dropFirst().first ?? "/tmp/point_cloud_animation.abc"
        let particleCount = 4_000
        let frameCount    = 120    // 5 seconds at 24 fps
        let fps: Float    = 24

        do {
            try writeAnimation(to: outputPath, particleCount: particleCount,
                               frameCount: frameCount, fps: fps)
            try await readAnimation(from: outputPath)
        } catch {
            fputs("Error: \(error)\n", stderr)
        }
    }
}

// MARK: - Minimal seeded PRNG (xorshift64)

struct SeededRandom {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 1 : seed }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }

    mutating func float(_ lo: Float, _ hi: Float) -> Float {
        let u = Float(next() & 0x00FF_FFFF) / Float(0x00FF_FFFF)
        return lo + u * (hi - lo)
    }
}
