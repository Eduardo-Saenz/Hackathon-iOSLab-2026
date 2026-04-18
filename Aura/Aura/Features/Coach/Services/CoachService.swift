import Foundation

protocol CoachServiceProtocol {
    func sendChat(
        messages: [ChatMessagePayload],
        healthContext: ChatHealthContextPayload?,
        sessionId: String?,
        sessionKind: ChatSessionKind?
    ) async throws -> ChatResponse

    func listChatSessions(sessionKind: ChatSessionKind?) async throws -> [ChatSessionSummary]
    func getChatSessionMessages(sessionId: String) async throws -> ChatSessionMessagesResponse
}

struct CoachAPIService: CoachServiceProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func sendChat(
        messages: [ChatMessagePayload],
        healthContext: ChatHealthContextPayload?,
        sessionId: String?,
        sessionKind: ChatSessionKind?
    ) async throws -> ChatResponse {
        let request = ChatRequest(
            messages: messages,
            healthContext: healthContext,
            sessionId: sessionId,
            sessionKind: sessionKind
        )
        let body = try JSONEncoder().encode(request)
        return try await apiClient.send(.chat(body: body))
    }

    func listChatSessions(sessionKind: ChatSessionKind?) async throws -> [ChatSessionSummary] {
        let response: ChatSessionsResponse = try await apiClient.send(.chatSessions(kind: sessionKind))
        return response.sessions
    }

    func getChatSessionMessages(sessionId: String) async throws -> ChatSessionMessagesResponse {
        try await apiClient.send(.chatSessionMessages(sessionId: sessionId))
    }
}

struct MockCoachService: CoachServiceProtocol {
    func sendChat(
        messages: [ChatMessagePayload],
        healthContext: ChatHealthContextPayload?,
        sessionId: String?,
        sessionKind: ChatSessionKind?
    ) async throws -> ChatResponse {
        let userMessage = messages.last(where: { $0.role == .user })?.content ?? "Cuéntame cómo te sientes hoy."
        return ChatResponse(
            message: "Gracias por compartir: \"\(userMessage)\". Vamos a convertirlo en una acción concreta y sencilla para hoy.",
            grounded: true,
            disclaimer: "Respuesta generada en modo mock.",
            sessionId: sessionId ?? UUID().uuidString
        )
    }

    func listChatSessions(sessionKind: ChatSessionKind?) async throws -> [ChatSessionSummary] {
        [
            ChatSessionSummary(
                id: UUID().uuidString,
                startedAt: ISO8601DateFormatter().string(from: Date()),
                lastMessageAt: ISO8601DateFormatter().string(from: Date()),
                snapshotId: nil,
                messageCount: 4,
                topic: "energy",
                sessionKind: sessionKind ?? .journal,
                journalDate: ISO8601DateFormatter().string(from: Date()).prefix(10).description,
                summary: nil,
                summaryUpdatedAt: nil,
                latestMessagePreview: "Hoy me sentí con más claridad después de caminar.",
                isToday: true,
                isWritable: true
            )
        ]
    }

    func getChatSessionMessages(sessionId: String) async throws -> ChatSessionMessagesResponse {
        ChatSessionMessagesResponse(
            session: ChatSessionMetadata(
                id: sessionId,
                sessionKind: .journal,
                journalDate: ISO8601DateFormatter().string(from: Date()).prefix(10).description,
                summary: nil,
                isToday: true,
                isWritable: true
            ),
            messages: [
                ChatSessionMessage(
                    id: UUID().uuidString,
                    role: .assistant,
                    content: "Hola, soy tu Coach AI. Estoy listo para ayudarte con acciones concretas para hoy.",
                    tokensUsed: nil,
                    aiProvider: nil,
                    createdAt: ISO8601DateFormatter().string(from: Date())
                )
            ]
        )
    }
}
