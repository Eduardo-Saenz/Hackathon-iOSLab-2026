import Foundation

protocol ActionsServiceProtocol {
    func healthCheck() async throws
    func generateDailyActions(
        userGoals: [String],
        healthSnapshot: HealthDataSnapshot,
        streakDays: Int?
    ) async throws -> GenerateActionsResponse
}

struct ActionsAPIService: ActionsServiceProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func healthCheck() async throws {
        struct HealthResponse: Decodable {
            let status: String?
        }
        let _: HealthResponse = try await apiClient.send(.health)
    }

    func generateDailyActions(
        userGoals: [String],
        healthSnapshot: HealthDataSnapshot,
        streakDays: Int?
    ) async throws -> GenerateActionsResponse {
        let request = GenerateActionsRequest(
            userGoals: userGoals,
            healthData: HealthKitMapper.mapToPayload(healthSnapshot),
            streakDays: streakDays
        )
        let body = try JSONEncoder().encode(request)
        return try await apiClient.send(.generateActions(body: body))
    }
}

struct MockActionsService: ActionsServiceProtocol {
    var response: GenerateActionsResponse = GenerateActionsResponse(
        microactions: [
            MicroAction(id: "mock-1", title: "Bebe un vaso de agua", description: "Hazlo ahora para hidratarte.", category: "hidratacion", difficulty: "facil", estimatedMinutes: 1, justification: "Mejora foco y energía."),
            MicroAction(id: "mock-2", title: "Camina 10 minutos", description: "Da una vuelta corta tras comer.", category: "actividad", difficulty: "facil", estimatedMinutes: 10, justification: "Ayuda a sumar pasos diarios."),
            MicroAction(id: "mock-3", title: "Respira 3 minutos", description: "Haz respiración lenta y profunda.", category: "mindfulness", difficulty: "facil", estimatedMinutes: 3, justification: "Reduce estrés y mejora claridad.")
        ],
        motivationMessage: "Pequeños pasos hoy crean grandes cambios mañana.",
        focusArea: "energy"
    )

    func healthCheck() async throws {}

    func generateDailyActions(
        userGoals: [String],
        healthSnapshot: HealthDataSnapshot,
        streakDays: Int?
    ) async throws -> GenerateActionsResponse {
        response
    }
}
