import Foundation

protocol EmotionsServiceProtocol {
    func submitCheckin(_ request: EmotionCheckinRequest) async throws -> EmotionCheckinResponse
    func getHistory(limit: Int, offset: Int) async throws -> EmotionHistoryResponse
}

struct EmotionsAPIService: EmotionsServiceProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func submitCheckin(_ request: EmotionCheckinRequest) async throws -> EmotionCheckinResponse {
        let encoder = JSONEncoder()
        let body = try encoder.encode(request)
        return try await apiClient.send(.emotionCheckin(body: body))
    }

    func getHistory(limit: Int = 20, offset: Int = 0) async throws -> EmotionHistoryResponse {
        try await apiClient.send(.emotionHistory(limit: limit, offset: offset))
    }
}

struct MockEmotionsService: EmotionsServiceProtocol {
    func submitCheckin(_ request: EmotionCheckinRequest) async throws -> EmotionCheckinResponse {
        EmotionCheckinResponse(
            id: UUID().uuidString,
            checkedAt: ISO8601DateFormatter().string(from: Date()),
            compassionateResponse: "Gracias por compartir cómo te sientes. Recuerda que cada emoción es válida y pasajera.",
            suggestedAdjustment: nil
        )
    }

    func getHistory(limit: Int = 20, offset: Int = 0) async throws -> EmotionHistoryResponse {
        let items: [EmotionHistoryItem] = [
            EmotionHistoryItem(id: "eh-1", checkedAt: ISO8601DateFormatter().string(from: Date()), checkinType: "morning", emotionFamily: "joy", emotionLabel: "Contento", valence: 0.7, arousal: 0.5, intensity: 6, triggerContext: nil, microactionId: nil, notes: nil),
            EmotionHistoryItem(id: "eh-2", checkedAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400)), checkinType: "evening", emotionFamily: "sadness", emotionLabel: "Melancolía", valence: -0.3, arousal: 0.2, intensity: 4, triggerContext: nil, microactionId: nil, notes: nil),
            EmotionHistoryItem(id: "eh-3", checkedAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-172800)), checkinType: "midday", emotionFamily: "anger", emotionLabel: "Frustración", valence: -0.5, arousal: 0.8, intensity: 7, triggerContext: nil, microactionId: nil, notes: nil),
        ]
        return EmotionHistoryResponse(items: items, limit: limit, offset: offset)
    }
}
