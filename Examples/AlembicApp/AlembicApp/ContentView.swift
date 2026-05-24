import SwiftUI
import Combine
import RealityKit
import SwiftAlembic
import simd

struct ContentView: View {
    @State private var frames: [[SIMD3<Float>]] = []
    @State private var status: String = "Generating animation…"
    @State private var currentFrame: Int = 0
    @State private var particleEntities: [ModelEntity] = []

    private let particleCount = 600
    private let frameCount = 90
    private let timer = Timer.publish(every: 1.0 / 24.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .topLeading) {
            RealityView { content in
                let root = Entity()
                root.position = [0, 0, -1.5]
                content.add(root)

                let mesh = MeshResource.generateSphere(radius: 0.012)
                var material = SimpleMaterial()
                material.color = .init(tint: .cyan)
                material.roughness = 0.4
                material.metallic = 0.1

                var built: [ModelEntity] = []
                built.reserveCapacity(particleCount)
                for _ in 0..<particleCount {
                    let e = ModelEntity(mesh: mesh, materials: [material])
                    root.addChild(e)
                    built.append(e)
                }
                Task { @MainActor in particleEntities = built }
            } update: { _ in
                applyFrame()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(status).font(.caption.monospaced())
                if !frames.isEmpty {
                    Text("frame \(currentFrame + 1) / \(frames.count)").font(.caption.monospaced())
                    Text("particles \(particleCount)").font(.caption.monospaced())
                }
            }
            .padding(10)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
            .padding()
        }
        .task { await loadAnimation() }
        .onReceive(timer) { _ in
            guard !frames.isEmpty else { return }
            currentFrame = (currentFrame + 1) % frames.count
        }
    }

    @MainActor
    private func applyFrame() {
        guard !frames.isEmpty, !particleEntities.isEmpty else { return }
        let positions = frames[currentFrame]
        let n = min(positions.count, particleEntities.count)
        let scale: Float = 0.06
        for i in 0..<n {
            particleEntities[i].position = positions[i] * scale
        }
    }

    private func loadAnimation() async {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("alembic_demo.abc")
        do {
            try await Task.detached(priority: .userInitiated) {
                try writeAnimation(to: tmp.path,
                                   particleCount: particleCount,
                                   frameCount: frameCount)
            }.value

            let loaded = try await Task.detached(priority: .userInitiated) {
                try readAnimation(from: tmp.path)
            }.value

            await MainActor.run {
                frames = loaded
                status = "Loaded \(loaded.count) frames from \(tmp.lastPathComponent)"
            }
        } catch {
            await MainActor.run { status = "Error: \(error.localizedDescription)" }
        }
    }
}

// MARK: - Alembic write/read

private nonisolated func writeAnimation(to path: String, particleCount: Int, frameCount: Int) throws {
    let particles = generateParticles(count: particleCount)
    try Alembic.withArchive(path: path) { archive in
        let writer = archive.top
            .createChild(name: "cloud")
            .addPoints(name: "points")
        for frame in 0..<frameCount {
            let t = Float(frame) / Float(frameCount) * .pi * 2
            var positions: [SIMD3<Float>] = []
            positions.reserveCapacity(particles.count)
            for p in particles {
                let angle = t * p.orbitSpeed + p.phase
                let x = p.orbitRadius * cos(angle)
                let z = p.orbitRadius * sin(angle)
                let y = p.position.y + sin(t * 2 + p.phase) * 0.5
                positions.append(SIMD3<Float>(x, y, z))
            }
            var sample = Alembic.PointsSample()
            sample.positions = positions
            try writer.set(sample)
        }
    }
}

private nonisolated func readAnimation(from path: String) throws -> [[SIMD3<Float>]] {
    let archive = try Alembic.InputArchive(path: path)
    guard let cloud = archive.top.children.first,
          let pointsObj = cloud.children.first,
          let reader = pointsObj.asPoints() else {
        throw NSError(domain: "AlembicApp", code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "No points schema found"])
    }
    var out: [[SIMD3<Float>]] = []
    out.reserveCapacity(reader.sampleCount)
    for i in 0..<reader.sampleCount {
        let s = try reader.sample(at: i)
        out.append(s.positions)
    }
    return out
}

// MARK: - Particle generation

private nonisolated struct Particle {
    var position: SIMD3<Float>
    var phase: Float
    var orbitRadius: Float
    var orbitSpeed: Float
}

private nonisolated func generateParticles(count: Int, seed: UInt64 = 42) -> [Particle] {
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
                         : rng.float(0.05, 0.2)
        return Particle(
            position: SIMD3<Float>(x, y, z),
            phase: rng.float(0, .pi * 2),
            orbitRadius: r,
            orbitSpeed: speed
        )
    }
}

private nonisolated struct SeededRandom {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0xdead_beef : seed }
    mutating func next() -> UInt64 {
        state ^= state << 13; state ^= state >> 7; state ^= state << 17
        return state
    }
    mutating func float(_ lo: Float, _ hi: Float) -> Float {
        let u = Float(next() & 0x00FF_FFFF) / Float(0x00FF_FFFF)
        return lo + u * (hi - lo)
    }
}

#Preview {
    ContentView()
}
