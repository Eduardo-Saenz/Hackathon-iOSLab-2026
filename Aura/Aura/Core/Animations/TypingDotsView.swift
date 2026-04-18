import SwiftUI

/// Three dots that pulse in sequence — calm typing indicator for Coach.
struct TypingDotsView: View {
    @State private var activeDot = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let dotSize: CGFloat = 8
    private let dotSpacing: CGFloat = 6

    var body: some View {
        HStack(spacing: dotSpacing) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(AuraColors.textSecondary.opacity(activeDot == index ? 0.8 : 0.3))
                    .frame(width: dotSize, height: dotSize)
                    .scaleEffect(activeDot == index ? 1.0 : 0.6)
                    .animation(
                        reduceMotion ? .default : .spring(response: 0.35, dampingFraction: 0.6),
                        value: activeDot
                    )
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            startPulsing()
        }
    }

    private func startPulsing() {
        Timer.scheduledTimer(withTimeInterval: 0.45, repeats: true) { _ in
            withAnimation {
                activeDot = (activeDot + 1) % 3
            }
        }
    }
}
