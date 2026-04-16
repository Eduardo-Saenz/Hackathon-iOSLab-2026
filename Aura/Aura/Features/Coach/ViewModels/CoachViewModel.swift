import Foundation
import Combine

struct CoachMessage: Identifiable {
    let id: UUID
    let text: String
    let isFromUser: Bool
    let time: String
}

@MainActor
final class CoachViewModel: ObservableObject {
    @Published var messages: [CoachMessage] = [
        CoachMessage(id: UUID(), text: "Bienestar AI. Noto que dormiste solo 5.2h anoche. ¿Cómo te sientes hoy?", isFromUser: false, time: "09:01"),
        CoachMessage(id: UUID(), text: "Un poco cansado la verdad", isFromUser: true, time: "09:04"),
        CoachMessage(id: UUID(), text: "Entiendo. Hoy vamos a enfocarnos en 3 micro-acciones que no requieren mucha energía: hidratarte bien, estirar 5 min y una caminata pequeña. ¿Empezamos? 💧", isFromUser: false, time: "09:04")
    ]
    @Published var quickReplies: [String] = [
        "¡Vamos! 💪",
        "¿Por qué dormir poco afecta mi energía?"
    ]
    @Published var draftMessage = ""

    func sendDraft() {
        let trimmed = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        messages.append(CoachMessage(id: UUID(), text: trimmed, isFromUser: true, time: "Ahora"))
        messages.append(CoachMessage(id: UUID(), text: "Perfecto, lo adaptaré en tus próximas acciones de hoy.", isFromUser: false, time: "Ahora"))
        draftMessage = ""
    }
}
