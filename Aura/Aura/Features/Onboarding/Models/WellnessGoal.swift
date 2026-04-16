import Foundation

struct WellnessGoal: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let iconName: String
}

extension WellnessGoal {
    static let predefined: [WellnessGoal] = [
        .init(id: "sleep", title: "Dormir mejor", subtitle: "Mejora tu descanso de forma gradual.", iconName: "bed.double.fill"),
        .init(id: "steps", title: "Caminar más", subtitle: "Aumenta tus pasos diarios.", iconName: "figure.walk"),
        .init(id: "energy", title: "Más energía", subtitle: "Hábitos para sentirte con más energía.", iconName: "bolt.heart.fill"),
        .init(id: "weight", title: "Control de peso", subtitle: "Avance sostenible y saludable.", iconName: "scalemass.fill"),
        .init(id: "hydration", title: "Hidratación", subtitle: "Mantén una mejor hidratación diaria.", iconName: "drop.fill"),
        .init(id: "stress", title: "Menos estrés", subtitle: "Reduce tensión con pequeñas pausas.", iconName: "brain.head.profile"),
        .init(id: "mindfulness", title: "Mindfulness", subtitle: "Mejora foco y calma mental.", iconName: "figure.mind.and.body")
    ]
}
