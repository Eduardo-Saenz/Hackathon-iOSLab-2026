import SwiftUI

/// A slowly shifting gradient overlay that morphs between calm colors.
/// Place behind the AI Coach / daily brief card for living depth.
struct GradientMorphView: View {
    @State private var animateGradient = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        LinearGradient(
            colors: [
                AuraColors.accentMint.opacity(0.15),
                AuraColors.accentLavender.opacity(0.12),
                AuraColors.blueSoft.opacity(0.1)
            ],
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }
}
