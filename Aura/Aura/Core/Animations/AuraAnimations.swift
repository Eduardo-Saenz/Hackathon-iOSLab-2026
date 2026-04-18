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

    /// Specialized curve for path drawing (logo).
    static let logoDrawing = Animation.easeInOut(duration: 1.5)

    /// Ultra-smooth spring for shared element transitions.
    static let silkTransition = Animation.spring(response: 0.8, dampingFraction: 0.85)

    /// A heavy, highly damped spring that feels like dragging through fluid. Ideal for structural gestures.
    static let liquidSpring = Animation.spring(response: 0.8, dampingFraction: 0.95, blendDuration: 0.1)
    
    /// Snappy but grounded spring for finalizing swipe-to-complete actions.
    static let cardSnap = Animation.spring(response: 0.4, dampingFraction: 0.8)
}
