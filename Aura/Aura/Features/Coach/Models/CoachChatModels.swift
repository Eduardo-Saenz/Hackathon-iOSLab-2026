import Foundation

enum ChatSessionKind: String, Codable {
    case general
    case journal
}

struct ChatRequest: Codable {
    let messages: [ChatMessagePayload]
    let healthContext: ChatHealthContextPayload?
    let sessionId: String?
    let sessionKind: ChatSessionKind?

    enum CodingKeys: String, CodingKey {
        case messages
        case healthContext = "health_context"
        case sessionId = "session_id"
        case sessionKind = "session_kind"
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

struct ChatSessionSummary: Codable, Identifiable {
    let id: String
    let startedAt: String?
    let lastMessageAt: String?
    let snapshotId: String?
    let messageCount: Int
    let topic: String?
    let sessionKind: ChatSessionKind
    let journalDate: String?
    let summary: String?
    let summaryUpdatedAt: String?
    let latestMessagePreview: String?
    let isToday: Bool
    let isWritable: Bool
}

struct ChatSessionsResponse: Codable {
    let sessions: [ChatSessionSummary]
}

struct ChatSessionMessage: Codable, Identifiable {
    let id: String
    let role: ChatMessagePayload.Role
    let content: String
    let tokensUsed: Int?
    let aiProvider: String?
    let createdAt: String?
}

struct ChatSessionMetadata: Codable {
    let id: String
    let sessionKind: ChatSessionKind
    let journalDate: String?
    let summary: String?
    let isToday: Bool
    let isWritable: Bool
}

struct ChatSessionMessagesResponse: Codable {
    let session: ChatSessionMetadata
    let messages: [ChatSessionMessage]
}
