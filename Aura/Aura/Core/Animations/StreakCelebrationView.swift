import SwiftUI

/// Gentle sparkle particles that float upward when a streak increases.
struct StreakCelebrationView: View {
    @Binding var isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var particles: [SparkleParticle] = []

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .offset(x: particle.x, y: particle.y)
                    .opacity(particle.opacity)
            }
        }
        .onChange(of: isActive) { _, newValue in
            guard newValue, !reduceMotion else { return }
            spawnParticles()
        }
        .allowsHitTesting(false)
    }

    private func spawnParticles() {
        let colors: [Color] = [
            AuraColors.accentMint,
            AuraColors.accentLavender,
            AuraColors.primary.opacity(0.7),
            Color.yellow.opacity(0.6)
        ]

        var newParticles: [SparkleParticle] = []
        for i in 0..<10 {
            let particle = SparkleParticle(
                id: UUID(),
                x: CGFloat.random(in: -40...40),
                y: 0,
                size: CGFloat.random(in: 3...7),
                color: colors[i % colors.count],
                opacity: 1.0
            )
            newParticles.append(particle)
        }
        particles = newParticles

        withAnimation(.easeOut(duration: 1.5)) {
            particles = particles.map { p in
                var updated = p
                updated.y = CGFloat.random(in: -80 ... -40)
                updated.x = p.x + CGFloat.random(in: -15...15)
                updated.opacity = 0
                return updated
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            particles = []
            isActive = false
        }
    }
}

private struct SparkleParticle: Identifiable {
    let id: UUID
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var opacity: Double
}
