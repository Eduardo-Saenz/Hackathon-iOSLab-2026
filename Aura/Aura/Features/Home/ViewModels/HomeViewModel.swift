import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var greeting = "Hola, Edu!"
    @Published var dateText = "15 de abril"
    @Published var summary = "Ayer fue un día exigente, pero cada nuevo amanecer es una oportunidad. Toma pequeñas pausas hoy; cuida tu energía y verás cómo logras todo lo que te propongas."
    @Published var healthStatusText = "Apple HealthKit no conectado"
    @Published var stepsToday = 0
    @Published var sleepHours = 0.0
    @Published var activeCalories = 0
    @Published var isRefreshing = false
    @Published var backendSyncStatusText = "Sincronización pendiente"
    @Published private(set) var completedActionIDs: Set<String> = []
    @Published private(set) var streakDays = 0
    @Published var actions: [MicroAction] = [
        MicroAction(
            id: "water",
            title: "Beber un vaso de agua",
            description: "Desliza para marcar",
            category: "hidratacion",
            difficulty: "facil",
            estimatedMinutes: 1,
            justification: "La hidratación mejora foco y energía."
        ),
        MicroAction(
            id: "stretch",
            title: "5 min de estiramiento",
            description: "Pendiente",
            category: "movilidad",
            difficulty: "facil",
            estimatedMinutes: 5,
            justification: "Reduce fatiga muscular."
        ),
        MicroAction(
            id: "walk",
            title: "Caminar 500 pasos ahora",
            description: "Auto-detectando...",
            category: "actividad",
            difficulty: "media",
            estimatedMinutes: 8,
            justification: "Activa circulación y claridad mental."
        )
    ]

    private let healthKitManager: HealthKitManaging
    private let apiClient: APIClientProtocol
    private let appPreferences: AppPreferences
    private let calendar = Calendar.current

    init() {
        self.healthKitManager = HealthKitManager()
        self.apiClient = APIClient()
        self.appPreferences = .shared
        configureDailyState()
    }

    init(healthKitManager: HealthKitManaging) {
        self.healthKitManager = healthKitManager
        self.apiClient = APIClient()
        self.appPreferences = .shared
        configureDailyState()
    }

    init(healthKitManager: HealthKitManaging, appPreferences: AppPreferences) {
        self.healthKitManager = healthKitManager
        self.apiClient = APIClient()
        self.appPreferences = appPreferences
        configureDailyState()
    }

    init(
        healthKitManager: HealthKitManaging,
        apiClient: APIClientProtocol,
        appPreferences: AppPreferences
    ) {
        self.healthKitManager = healthKitManager
        self.apiClient = apiClient
        self.appPreferences = appPreferences
        configureDailyState()
    }

    func loadHealthData() async {
        configureDailyState()

        healthKitManager.refreshAuthorizationState()

        if healthKitManager.authorizationState == .notRequested {
            await healthKitManager.requestAuthorization()
        }

        switch healthKitManager.authorizationState {
        case .authorized:
            do {
                let summaryData = try await healthKitManager.fetchDailySummary()
                stepsToday = summaryData.stepsToday
                sleepHours = summaryData.sleepHoursLastNight
                activeCalories = Int(summaryData.activeCaloriesToday.rounded())
                healthStatusText = "Apple HealthKit conectado"
            } catch {
                healthStatusText = "Error sincronizando HealthKit"
            }
        case .requesting:
            healthStatusText = "Conectando HealthKit..."
        case .denied:
            healthStatusText = "Permiso de HealthKit denegado"
        case .unavailable:
            healthStatusText = "HealthKit no disponible"
        case .notRequested:
            healthStatusText = "HealthKit no conectado"
        }
    }

    func refreshData() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        await loadHealthData()
        await fetchDailyActionsFromBackend()
    }

    var completedCount: Int {
        completedActionIDs.count
    }

    func isActionCompleted(_ actionID: String) -> Bool {
        completedActionIDs.contains(actionID)
    }

    func toggleActionCompletion(_ actionID: String) {
        if completedActionIDs.contains(actionID) {
            completedActionIDs.remove(actionID)
        } else {
            completedActionIDs.insert(actionID)
        }

        persistCompletedActionsForToday()
        updateStreakIfDailyGoalCompleted()
    }

    func completeAllActions() {
        completedActionIDs = Set(actions.map(\.id))
        persistCompletedActionsForToday()
        updateStreakIfDailyGoalCompleted()
    }

    private func configureDailyState() {
        resetStreakIfNeededForSkippedDays()
        loadTodayCompletedActions()
        streakDays = appPreferences.streakDays
        dateText = Self.dateFormatter.string(from: Date())
    }

    private func resetStreakIfNeededForSkippedDays() {
        guard let lastCompletedDate = appPreferences.lastCompletedActionsDate else {
            return
        }

        let today = calendar.startOfDay(for: Date())
        let completedDay = calendar.startOfDay(for: lastCompletedDate)
        let dayDelta = calendar.dateComponents([.day], from: completedDay, to: today).day ?? 0

        if dayDelta > 1 {
            appPreferences.streakDays = 0
            streakDays = 0
        }
    }

    private func loadTodayCompletedActions() {
        guard let savedDate = appPreferences.completedActionIDsDate else {
            completedActionIDs = []
            return
        }

        if calendar.isDateInToday(savedDate) {
            completedActionIDs = Set(appPreferences.completedActionIDs)
        } else {
            completedActionIDs = []
            appPreferences.completedActionIDs = []
            appPreferences.completedActionIDsDate = nil
        }
    }

    private func persistCompletedActionsForToday() {
        appPreferences.completedActionIDs = Array(completedActionIDs)
        appPreferences.completedActionIDsDate = Date()
    }

    private func updateStreakIfDailyGoalCompleted() {
        guard completedActionIDs.count == actions.count else {
            return
        }

        let today = calendar.startOfDay(for: Date())
        let previousCompletionDate = appPreferences.lastCompletedActionsDate.map { calendar.startOfDay(for: $0) }

        if let previousCompletionDate, calendar.isDate(previousCompletionDate, inSameDayAs: today) {
            return
        }

        if let previousCompletionDate,
           let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
           calendar.isDate(previousCompletionDate, inSameDayAs: yesterday) {
            appPreferences.streakDays += 1
        } else {
            appPreferences.streakDays = 1
        }

        appPreferences.lastCompletedActionsDate = today
        streakDays = appPreferences.streakDays
    }

    private func fetchDailyActionsFromBackend() async {
        let request = GenerateActionsRequest(
            userGoals: appPreferences.selectedGoalIDs,
            healthData: HealthDataPayload(
                stepsToday: stepsToday,
                stepsGoal: 8000,
                sleepHoursLastNight: sleepHours,
                sleepGoalHours: 8.0,
                activeCaloriesToday: Double(activeCalories)
            ),
            streakDays: streakDays
        )

        do {
            let endpoint = try makeGenerateActionsEndpoint(request)
            let response: GenerateActionsResponse = try await apiClient.send(endpoint)

            actions = Array(response.microactions.prefix(3))
            summary = response.motivationMessage
            backendSyncStatusText = "Acciones actualizadas desde backend"
            reconcileCompletedActionsWithCurrentActions()
        } catch {
            backendSyncStatusText = "No se pudieron actualizar acciones del backend"
        }
    }

    private func makeGenerateActionsEndpoint(_ payload: GenerateActionsRequest) throws -> Endpoint {
        let body = try JSONEncoder().encode(payload)
        return Endpoint(
            path: "/generate-actions",
            method: .post,
            headers: [:],
            body: body
        )
    }

    private func reconcileCompletedActionsWithCurrentActions() {
        let validIDs = Set(actions.map(\.id))
        completedActionIDs = completedActionIDs.intersection(validIDs)
        persistCompletedActionsForToday()
    }
}
private extension HomeViewModel {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "d 'de' MMMM"
        return formatter
    }()
}
