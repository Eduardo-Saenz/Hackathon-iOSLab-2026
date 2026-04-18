import SwiftUI

/// Subtle translucent circles that drift slowly across the screen.
/// Use as a background layer on Home and Coach screens.
struct FloatingOrbsView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let orbs: [OrbConfig] = [
        OrbConfig(color: AuraColors.accentMint, size: 120, blur: 40, startX: 0.2, startY: 0.3, driftX: 30, driftY: -20, duration: 7),
        OrbConfig(color: AuraColors.accentLavender, size: 90, blur: 35, startX: 0.7, startY: 0.15, driftX: -25, driftY: 15, duration: 6),
        OrbConfig(color: AuraColors.primary, size: 100, blur: 45, startX: 0.5, startY: 0.7, driftX: 20, driftY: -30, duration: 8),
        OrbConfig(color: AuraColors.accentMint, size: 70, blur: 30, startX: 0.1, startY: 0.8, driftX: 15, driftY: -10, duration: 5.5),
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(orbs.indices, id: \.self) { i in
                    OrbView(config: orbs[i], containerSize: geo.size, reduceMotion: reduceMotion)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct OrbConfig {
    let color: Color
    let size: CGFloat
    let blur: CGFloat
    let startX: CGFloat
    let startY: CGFloat
    let driftX: CGFloat
    let driftY: CGFloat
    let duration: Double
}

private struct OrbView: View {
    let config: OrbConfig
    let containerSize: CGSize
    let reduceMotion: Bool

    @State private var isDrifting = false

    var body: some View {
        Circle()
            .fill(config.color.opacity(0.1))
            .frame(width: config.size, height: config.size)
            .blur(radius: config.blur)
            .position(
                x: containerSize.width * config.startX + (isDrifting ? config.driftX : 0),
                y: containerSize.height * config.startY + (isDrifting ? config.driftY : 0)
            )
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: config.duration).repeatForever(autoreverses: true)) {
                    isDrifting = true
                }
            }
    }
}
