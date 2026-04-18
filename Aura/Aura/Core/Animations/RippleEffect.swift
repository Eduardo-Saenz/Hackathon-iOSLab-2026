import SwiftUI

/// A calm water-ripple ring that expands outward and fades.
/// Triggered on microaction completion.
struct RippleModifier: ViewModifier {
    var trigger: Bool
    var color: Color = AuraColors.accentMint

    @State private var rippleScale: CGFloat = 0.5
    @State private var rippleOpacity: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .stroke(color, lineWidth: 2)
                    .scaleEffect(rippleScale)
                    .opacity(rippleOpacity)
            )
            .onChange(of: trigger) { _, newValue in
                guard newValue, !reduceMotion else { return }
                rippleScale = 0.5
                rippleOpacity = 0.6
                withAnimation(.easeOut(duration: 1.2)) {
                    rippleScale = 2.5
                    rippleOpacity = 0.0
                }
            }
    }
}

extension View {
    func rippleOnTap(trigger: Bool, color: Color = AuraColors.accentMint) -> some View {
        modifier(RippleModifier(trigger: trigger, color: color))
    }
}
