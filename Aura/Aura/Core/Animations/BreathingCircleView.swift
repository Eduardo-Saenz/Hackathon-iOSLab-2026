import SwiftUI

/// Pulsing concentric rings that expand and contract like slow breathing.
/// Place behind the AI Coach card on Home for a serene background effect.
struct BreathingCircleView: View {
    @State private var isExpanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            breathRing(delay: 0, maxScale: 1.15, maxOpacity: 0.5)
            breathRing(delay: 1.3, maxScale: 1.08, maxOpacity: 0.35)
            breathRing(delay: 2.6, maxScale: 1.22, maxOpacity: 0.2)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(AuraAnimations.breathe) {
                isExpanded = true
            }
        }
    }

    private func breathRing(delay: Double, maxScale: CGFloat, maxOpacity: Double) -> some View {
        Circle()
            .stroke(
                LinearGradient(
                    colors: [
                        AuraColors.accentMint.opacity(0.4),
                        AuraColors.accentLavender.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.5
            )
            .scaleEffect(isExpanded ? maxScale : 0.88)
            .opacity(isExpanded ? maxOpacity : 0.15)
            .animation(
                reduceMotion ? .default : Animation.easeInOut(duration: 4.0).repeatForever(autoreverses: true).delay(delay),
                value: isExpanded
            )
    }
}
