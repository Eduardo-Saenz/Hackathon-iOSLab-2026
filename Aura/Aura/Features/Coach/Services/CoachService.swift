import Foundation

protocol CoachServiceProtocol {
    func sendChat(
        messages: [ChatMessagePayload],
        healthContext: ChatHealthContextPayload?
    ) async throws -> ChatResponse
}

struct CoachAPIService: CoachServiceProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func sendChat(
        messages: [ChatMessagePayload],
        healthContext: ChatHealthContextPayload?
    ) async throws -> ChatResponse {
        let request = ChatRequest(messages: messages, healthContext: healthContext)
        let body = try JSONEncoder().encode(request)
        return try await apiClient.send(.chat(body: body))
    }
}

struct MockCoachService: CoachServiceProtocol {
    func sendChat(
        messages: [ChatMessagePayload],
        healthContext: ChatHealthContextPayload?
    ) async throws -> ChatResponse {
        let userMessage = messages.last(where: { $0.role == .user })?.content ?? "Cuéntame cómo te sientes hoy."
        return ChatResponse(
            message: "Gracias por compartir: \"\(userMessage)\". Vamos a convertirlo en una acción concreta y sencilla para hoy.",
            grounded: true,
            disclaimer: "Respuesta generada en modo mock."
        )
    }
}
