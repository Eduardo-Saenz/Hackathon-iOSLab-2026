import SwiftUI

/// A calm shimmer gradient that slides across a placeholder shape.
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: phase * geo.size.width)
                    .onAppear {
                        guard !reduceMotion else { return }
                        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false)) {
                            phase = 1.3
                        }
                    }
                }
            )
            .clipped()
    }
}

/// A rounded rectangle placeholder with shimmer.
struct ShimmerPlaceholder: View {
    var height: CGFloat = 80
    var cornerRadius: CGFloat = AuraCorners.medium

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(AuraColors.surfaceMuted)
            .frame(height: height)
            .modifier(ShimmerModifier())
    }
}
