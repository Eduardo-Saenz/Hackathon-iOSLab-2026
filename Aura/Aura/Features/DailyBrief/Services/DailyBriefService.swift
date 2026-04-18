import Foundation

protocol DailyBriefServiceProtocol {
    func getDailyBrief() async throws -> DailyBrief
    func postHealthSummary(_ request: HealthSummaryRequest) async throws -> HealthSummaryResponse
}

struct DailyBriefAPIService: DailyBriefServiceProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func getDailyBrief() async throws -> DailyBrief {
        try await apiClient.send(.dailyBrief)
    }

    func postHealthSummary(_ request: HealthSummaryRequest) async throws -> HealthSummaryResponse {
        let encoder = JSONEncoder()
        let body = try encoder.encode(request)
        return try await apiClient.send(.healthSummary(body: body))
    }
}

struct MockDailyBriefService: DailyBriefServiceProtocol {
    func getDailyBrief() async throws -> DailyBrief {
        DailyBrief(
            date: ISO8601DateFormatter().string(from: Date()),
            primaryMicroaction: MicroactionWithStatus(
                id: "mock-primary", title: "Camina 10 minutos", description: "Da una vuelta corta.",
                justification: "Activa tu cuerpo.", category: "steps", difficulty: "easy",
                estimatedMinutes: 10, scheduleHint: .morning, status: .pending,
                completedAt: nil, skippedAt: nil
            ),
            supportingActions: [],
            motivationMessage: "Cada pequeño paso cuenta. Hoy es un buen día para cuidarte.",
            focusArea: "energy",
            whyThisToday: "Tu sueño fue corto anoche, así que priorizamos energía.",
            recoveryMode: false,
            lastEmotion: nil,
            streak: DailyBriefStreak(current: 5, longest: 12, actionCompletionCurrent: 3, actionCompletionLongest: 8),
            adaptationNote: nil,
            recoveryNote: nil
        )
    }

    func postHealthSummary(_ request: HealthSummaryRequest) async throws -> HealthSummaryResponse {
        HealthSummaryResponse(
            summary: "Esta semana tu sueño mejoró en promedio 30 minutos. Tus pasos se mantienen consistentes.",
            insights: ["Dormiste más los días que completaste microacciones.", "Tu energía reportada correlaciona con mejor sueño."]
        )
    }
}
