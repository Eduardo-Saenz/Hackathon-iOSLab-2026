import SwiftUI

enum AuraAnimations {
    /// Standard calm spring for general transitions.
    static let calm = Animation.spring(response: 0.6, dampingFraction: 0.82)

    /// Gentle entrance for cards and elements appearing.
    static let entrance = Animation.spring(response: 0.7, dampingFraction: 0.85)

    /// Breath-like loop for pulsing backgrounds.
    static let breathe = Animation.easeInOut(duration: 4.0).repeatForever(autoreverses: true)

    /// Slow floating drift for background orbs.
    static let float = Animation.easeInOut(duration: 6.0).repeatForever(autoreverses: true)

    /// Ripple expansion on action completion.
    static let ripple = Animation.easeOut(duration: 1.2)

    /// Staggered delay per index for list entrances.
    static func staggered(index: Int, base: Animation = .spring(response: 0.5, dampingFraction: 0.8)) -> Animation {
        base.delay(Double(index) * 0.08)
    }

    /// Soft glow pulse for selections.
    static let glowPulse = Animation.easeInOut(duration: 0.6)
}
