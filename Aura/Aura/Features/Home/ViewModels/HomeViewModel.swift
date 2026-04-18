import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case content
        case partial
        case error(String)
    }

    @Published var greeting = "Hola, Edu!"
    @Published var dateText = "15 de abril"
    @Published var summary = "Ayer fue un día exigente, pero cada nuevo amanecer es una oportunidad. Toma pequeñas pausas hoy; cuida tu energía y verás cómo logras todo lo que te propongas."
    @Published var focusArea: String?
    @Published var healthStatusText = "Apple HealthKit no conectado"
    @Published var backendSyncStatusText = "Sincronización pendiente"
    @Published var backendModeText = "No inicializado"
    @Published var diagnosticFirstActionID: String = "-"
    @Published var lastRefreshText: String = "-"
    @Published private(set) var diagnosticsVisible = false
    @Published var stepsToday = 0
    @Published var sleepHours = 0.0
    @Published var activeCalories = 0
    @Published var isRefreshing = false
    @Published private(set) var loadState: LoadState = .idle
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
    private let healthDataProvider: HealthDataProviding
    private let fallbackHealthDataProvider: HealthDataProviding
    private let actionsService: ActionsServiceProtocol
    private let appPreferences: AppPreferences
    private let calendar = Calendar.current

    init() {
        if Self.isRunningInPreview {
            let mockHealthProvider = MockHealthDataProvider()
            self.healthKitManager = HealthKitManager()
            self.healthDataProvider = mockHealthProvider
            self.fallbackHealthDataProvider = mockHealthProvider
            self.actionsService = MockActionsService()
            self.appPreferences = .shared
            self.backendModeText = "Preview/Mock service"
        } else {
            let manager = HealthKitManager()
            self.healthKitManager = manager
            self.healthDataProvider = HealthKitHealthDataProvider(healthKitManager: manager)
            self.fallbackHealthDataProvider = MockHealthDataProvider()
            self.actionsService = ActionsAPIService(apiClient: APIClient())
            self.appPreferences = .shared
            self.backendModeText = "Runtime/API service"
        }
        Self.debugLog("HomeViewModel init with mode: \(backendModeText)")
        configureDailyState()
    }

    init(
        healthKitManager: HealthKitManaging,
        healthDataProvider: HealthDataProviding,
        fallbackHealthDataProvider: HealthDataProviding,
        actionsService: ActionsServiceProtocol,
        appPreferences: AppPreferences
    ) {
        self.healthKitManager = healthKitManager
        self.healthDataProvider = healthDataProvider
        self.fallbackHealthDataProvider = fallbackHealthDataProvider
        self.actionsService = actionsService
        self.appPreferences = appPreferences
        self.backendModeText = "Injected dependencies"
        Self.debugLog("HomeViewModel init with injected dependencies")
        configureDailyState()
    }

    func refreshData() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        loadState = .loading
        Self.debugLog("refreshData() triggered")
        defer { isRefreshing = false }

        configureDailyState()
        lastRefreshText = Self.timeFormatter.string(from: Date())

        do {
            try await actionsService.healthCheck()
            Self.debugLog("GET /health OK")
        } catch {
            Self.debugLog("GET /health failed: \(error.localizedDescription)")
        }

        let snapshot = await refreshHealthData()
        await refreshActions(snapshot: snapshot)
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

    private func refreshHealthData() async -> HealthDataSnapshot? {
        healthKitManager.refreshAuthorizationState()

        do {
            let snapshot = try await healthDataProvider.fetchCurrentSnapshot()
            stepsToday = snapshot.stepsToday
            sleepHours = snapshot.sleepHoursLastNight
            activeCalories = Int(snapshot.activeCaloriesToday.rounded())
            healthStatusText = "Apple HealthKit conectado"
            return snapshot
        } catch {
            switch healthKitManager.authorizationState {
            case .requesting:
                healthStatusText = "Conectando HealthKit..."
            case .denied:
                healthStatusText = "Permiso de HealthKit denegado"
            case .unavailable:
                healthStatusText = "HealthKit no disponible"
            case .notRequested:
                healthStatusText = "HealthKit no conectado"
            case .authorized:
                healthStatusText = "Error sincronizando HealthKit"
            }

            if Self.isSimulator {
                do {
                    let mockSnapshot = try await fallbackHealthDataProvider.fetchCurrentSnapshot()
                    healthStatusText = "HealthKit no disponible en simulador (usando datos de prueba)"
                    stepsToday = mockSnapshot.stepsToday
                    sleepHours = mockSnapshot.sleepHoursLastNight
                    activeCalories = Int(mockSnapshot.activeCaloriesToday.rounded())
                    return mockSnapshot
                } catch {
                    return nil
                }
            }

            return nil
        }
    }

    private func refreshActions(snapshot: HealthDataSnapshot?) async {
        guard let snapshot else {
            backendSyncStatusText = "No se pudieron generar acciones (falta snapshot de salud)"
            loadState = .partial
            return
        }

        do {
            let response = try await actionsService.generateDailyActions(
                userGoals: resolvedUserGoals(),
                healthSnapshot: snapshot,
                streakDays: streakDays
            )

            actions = Array(response.microactions.prefix(3))
            summary = response.motivationMessage
            focusArea = response.focusArea
            diagnosticFirstActionID = response.microactions.first?.id ?? "-"
            backendSyncStatusText = "Acciones actualizadas desde backend"
            reconcileCompletedActionsWithCurrentActions()
            loadState = .content
            Self.debugLog("generate-actions OK. firstActionID=\(diagnosticFirstActionID), count=\(actions.count)")
        } catch {
            backendSyncStatusText = "No se pudieron actualizar acciones del backend"
            loadState = .error(error.localizedDescription)
            Self.debugLog("generate-actions error: \(error.localizedDescription)")
        }
    }

    private func resolvedUserGoals() -> [String] {
        let persistedGoals = appPreferences.selectedGoalIDs
        if persistedGoals.isEmpty {
            return Array(WellnessGoal.predefined.prefix(3).map(\.id))
        }
        return Array(persistedGoals.prefix(3))
    }

    private func configureDailyState() {
        resetStreakIfNeededForSkippedDays()
        loadTodayCompletedActions()
        streakDays = appPreferences.streakDays
        diagnosticsVisible = appPreferences.diagnosticsVisible
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

    private func reconcileCompletedActionsWithCurrentActions() {
        let validIDs = Set(actions.map(\.id))
        completedActionIDs = completedActionIDs.intersection(validIDs)
        persistCompletedActionsForToday()
    }
}

private extension HomeViewModel {
    static var isRunningInPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "d 'de' MMMM"
        return formatter
    }()

    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter
    }()

    static func debugLog(_ message: String) {
        #if DEBUG
        print("🏠 HomeVM -> \(message)")
        #endif
    }
}
