import Foundation

enum EmotionMapping {

    /// Maps Spanish primary emotion labels to backend EmotionFamily.
    static func familyForSpanish(_ label: String) -> EmotionFamily {
        switch label.uppercased() {
        case "IRA":        return .anger
        case "ASCO":       return .disgust
        case "TRISTEZA":   return .sadness
        case "FELICIDAD":  return .joy
        case "SORPRESA":   return .surprise
        case "MIEDO":      return .fear
        case "ESTRÉS":     return .fear
        default:           return .joy
        }
    }

    /// The emotion chip labels used in HomeView.
    static let homeChipEmotions = ["Ira", "Asco", "Felicidad", "Tristeza", "Sorpresa", "Miedo", "Estrés"]

    /// Maps the 6 primary wheel emotions (uppercase) to EmotionFamily.
    static func familyForWheelPrimary(_ label: String) -> EmotionFamily {
        familyForSpanish(label)
    }

    /// Determines CheckinType from the current hour.
    static func currentCheckinType() -> CheckinType {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return .morning
        case 12..<17: return .midday
        case 17..<24: return .evening
        default:      return .manual
        }
    }
}
