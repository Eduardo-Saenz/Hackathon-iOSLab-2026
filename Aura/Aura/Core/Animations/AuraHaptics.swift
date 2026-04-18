import SwiftUI

/// Centralized haptic feedback generator to create physical synergy with fluid animations.
/// Using sensory feedback alongside motion creates the illusion of "living matter".
public enum AuraHaptics {
    
    /// For subtle interactions, like typing or minor state changes.
    public static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// For standard button presses or general interaction.
    public static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Creates a sharp, physical sensation. Excellent for boundary snapping.
    public static func rigid() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// A soft pulse. Ideal for meditative or generative AI text reveals.
    public static func soft() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// For smooth list scrolling or slider adjustments.
    public static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    /// For completing a habit or confirming a positive action.
    public static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
}
