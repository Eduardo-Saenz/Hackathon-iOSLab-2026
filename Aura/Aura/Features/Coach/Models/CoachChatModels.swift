import Foundation

struct ChatRequest: Codable {
    let messages: [ChatMessagePayload]
    let healthContext: ChatHealthContextPayload?
    let sessionId: String?

    enum CodingKeys: String, CodingKey {
        case messages
        case healthContext = "health_context"
        case sessionId = "session_id"
    }
}

struct ChatMessagePayload: Codable {
    enum Role: String, Codable {
        case user
        case assistant
    }

    let role: Role
    let content: String
}

struct ChatHealthContextPayload: Codable {
    let healthData: HealthDataPayload
    let userGoals: [String]

    enum CodingKeys: String, CodingKey {
        case healthData = "health_data"
        case userGoals = "user_goals"
    }
}

struct ChatResponse: Codable {
    let message: String
    let grounded: Bool
    let disclaimer: String
    let sessionId: String?
}
