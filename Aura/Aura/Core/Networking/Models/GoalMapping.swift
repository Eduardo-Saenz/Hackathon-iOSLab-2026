import Foundation

enum GoalMapping {

    static let validBackendGoals: Set<String> = ["sleep", "steps", "energy", "weight"]

    /// Maps an onboarding goal ID to a valid backend goal string.
    static func mapToBackend(_ goalId: String) -> String? {
        switch goalId {
        case "sleep":       return "sleep"
        case "steps":       return "steps"
        case "energy":      return "energy"
        case "hydration":   return "energy"
        case "stress":      return "energy"
        case "mindfulness": return "energy"
        default:            return nil
        }
    }

    /// Maps an array of onboarding goal IDs to deduplicated backend goals.
    static func mapGoals(_ goalIds: [String]) -> [String] {
        let mapped = goalIds.compactMap { mapToBackend($0) }
        return Array(Set(mapped))
    }
}
