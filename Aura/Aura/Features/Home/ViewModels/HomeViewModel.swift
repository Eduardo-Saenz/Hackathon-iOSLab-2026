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

    @Published var greeting = "Hola!"
    @Published var dateText = ""
    @Published var summary = "Preparando tu día..."
    @Published var focusArea: String?
    @Published var whyThisToday: String?
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
    @Published private(set) var streakLongest = 0
    @Published var sessionId: String?
    @Published var compassionateResponse: String?
    @Published var showStreakCelebration = false
    @Published var dailyBrief: DailyBrief?
    @Published var actions: [MicroAction] = [
        MicroAction(
            id: "water", title: "Beber un vaso de agua",
            description: "Desliza para marcar", category: "hidratacion",
            difficulty: "facil", estimatedMinutes: 1,
            justification: "La hidratación mejora foco y energía."
        ),
        MicroAction(
            id: "stretch", title: "5 min de estiramiento",
            description: "Pendiente", category: "movilidad",
            difficulty: "facil", estimatedMinutes: 5,
            justification: "Reduce fatiga muscular."
        ),
        MicroAction(
            id: "walk", title: "Caminar 500 pasos ahora",
            description: "Auto-detectando...", category: "actividad",
            difficulty: "media", estimatedMinutes: 8,
            justification: "Activa circulación y claridad mental."
        )
    ]

    private let healthKitManager: HealthKitManaging
    private let healthDataProvider: HealthDataProviding
    private let fallbackHealthDataProvider: HealthDataProviding
    private let actionsService: ActionsServiceProtocol
    private let userService: UserServiceProtocol
    private let dailyBriefService: DailyBriefServiceProtocol
    private let emotionsService: EmotionsServiceProtocol
    private let appPreferences: AppPreferences
    private let calendar = Calendar.current

    init() {
        if Self.isRunningInPreview {
            let mockHealthProvider = MockHealthDataProvider()
            self.healthKitManager = HealthKitManager()
            self.healthDataProvider = mockHealthProvider
            self.fallbackHealthDataProvider = mockHealthProvider
            self.actionsService = MockActionsService()
            self.userService = MockUserService()
            self.dailyBriefService = MockDailyBriefService()
            self.emotionsService = MockEmotionsService()
            self.appPreferences = .shared
            self.backendModeText = "Preview/Mock service"
        } else {
            let manager = HealthKitManager()
            let client = APIClient()
            self.healthKitManager = manager
            self.healthDataProvider = HealthKitHealthDataProvider(healthKitManager: manager)
            self.fallbackHealthDataProvider = MockHealthDataProvider()
            self.actionsService = ActionsAPIService(apiClient: client)
            self.userService = UserAPIService(apiClient: client)
            self.dailyBriefService = DailyBriefAPIService(apiClient: client)
            self.emotionsService = EmotionsAPIService(apiClient: client)
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
        userService: UserServiceProtocol,
        dailyBriefService: DailyBriefServiceProtocol,
        emotionsService: EmotionsServiceProtocol,
        appPreferences: AppPreferences
    ) {
        self.healthKitManager = healthKitManager
        self.healthDataProvider = healthDataProvider
        self.fallbackHealthDataProvider = fallbackHealthDataProvider
        self.actionsService = actionsService
        self.userService = userService
        self.dailyBriefService = dailyBriefService
        self.emotionsService = emotionsService
        self.appPreferences = appPreferences
        self.backendModeText = "Injected dependencies"
        Self.debugLog("HomeViewModel init with injected dependencies")
        configureDailyState()
    }

    // MARK: - Refresh

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

        // Fetch daily brief, streak, user, and health in parallel
        async let briefTask: () = fetchDailyBrief()
        async let streakTask: () = fetchStreak()
        async let userTask: () = fetchUserName()
        let snapshot = await refreshHealthData()
        await briefTask
        await streakTask
        await userTask

        await refreshActions(snapshot: snapshot)
    }

    // MARK: - Daily Brief

    private func fetchDailyBrief() async {
        do {
            let brief = try await dailyBriefService.getDailyBrief()
            dailyBrief = brief
            // Use daily brief motivation if available
            if !brief.motivationMessage.isEmpty {
                summary = brief.motivationMessage
            }
            if !brief.focusArea.isEmpty {
                focusArea = brief.focusArea
            }
            whyThisToday = brief.whyThisToday
            Self.debugLog("GET /daily-brief OK")
        } catch {
            Self.debugLog("GET /daily-brief failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Streak (Server)

    private func fetchStreak() async {
        do {
            let bundle = try await userService.getStreak()
            let previousStreak = streakDays
            streakDays = bundle.actionCompletion.current
            streakLongest = bundle.actionCompletion.longest
            // Celebrate if streak increased
            if streakDays > previousStreak && previousStreak > 0 {
                showStreakCelebration = true
            }
            Self.debugLog("GET /users/me/streak OK: \(streakDays)")
        } catch {
            // Fallback to local
            streakDays = appPreferences.streakDays
            Self.debugLog("GET /streak failed, using local: \(streakDays)")
        }
    }

    // MARK: - User Name

    private func fetchUserName() async {
        do {
            let user = try await userService.getMe()
            if let name = user.name, !name.isEmpty {
                greeting = "Hola, \(name)!"
                appPreferences.cachedUserName = name
            }
        } catch {
            if let cached = appPreferences.cachedUserName {
                greeting = "Hola, \(cached)!"
            }
        }
    }

    // MARK: - Emotions

    func submitEmotion(label: String) async {
        let family = EmotionMapping.familyForSpanish(label)
        let request = EmotionCheckinRequest(
            checkinType: EmotionMapping.currentCheckinType(),
            emotionFamily: family,
            emotionLabel: label,
            intensity: 5,
            triggerContext: nil,
            microactionId: nil,
            notes: nil
        )

        do {
            let response = try await emotionsService.submitCheckin(request)
            compassionateResponse = response.compassionateResponse
            Self.debugLog("POST /emotions/checkin OK")
        } catch {
            Self.debugLog("POST /emotions/checkin failed: \(error.localizedDescription)")
            compassionateResponse = "Gracias por compartir cómo te sientes."
        }
    }

    // MARK: - Actions

    var completedCount: Int { completedActionIDs.count }

    func isActionCompleted(_ actionID: String) -> Bool {
        completedActionIDs.contains(actionID)
    }

    func toggleActionCompletion(_ actionID: String) {
        let wasCompleted = completedActionIDs.contains(actionID)

        // Optimistic local update
        if wasCompleted {
            completedActionIDs.remove(actionID)
        } else {
            completedActionIDs.insert(actionID)
        }
        persistCompletedActionsForToday()

        // Server call
        guard let sid = sessionId else {
            updateStreakIfDailyGoalCompleted()
            return
        }

        Task {
            do {
                if wasCompleted {
                    // No "uncomplete" endpoint — keep local state
                } else {
                    _ = try await actionsService.completeAction(sessionId: sid, actionId: actionID)
                    Self.debugLog("PATCH complete OK for \(actionID)")
                }
                updateStreakIfDailyGoalCompleted()
            } catch {
                // Revert on failure
                if wasCompleted {
                    completedActionIDs.insert(actionID)
                } else {
                    completedActionIDs.remove(actionID)
                }
                persistCompletedActionsForToday()
                Self.debugLog("PATCH complete failed: \(error.localizedDescription)")
            }
        }
    }

    func completeAllActions() {
        completedActionIDs = Set(actions.map(\.id))
        persistCompletedActionsForToday()
        updateStreakIfDailyGoalCompleted()
    }

    // MARK: - Private: Health Data

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
            case .requesting: healthStatusText = "Conectando HealthKit..."
            case .denied:     healthStatusText = "Permiso de HealthKit denegado"
            case .unavailable: healthStatusText = "HealthKit no disponible"
            case .notRequested: healthStatusText = "HealthKit no conectado"
            case .authorized: healthStatusText = "Error sincronizando HealthKit"
            }

            if Self.isSimulator {
                do {
                    let mockSnapshot = try await fallbackHealthDataProvider.fetchCurrentSnapshot()
                    healthStatusText = "HealthKit no disponible en simulador (usando datos de prueba)"
                    stepsToday = mockSnapshot.stepsToday
                    sleepHours = mockSnapshot.sleepHoursLastNight
                    activeCalories = Int(mockSnapshot.activeCaloriesToday.rounded())
                    return mockSnapshot
                } catch { return nil }
            }
            return nil
        }
    }

    // MARK: - Private: Actions Refresh

    private func refreshActions(snapshot: HealthDataSnapshot?) async {
        guard let snapshot else {
            backendSyncStatusText = "No se pudieron generar acciones (falta snapshot de salud)"
            loadState = .partial
            return
        }

        // Try cached actions first
        do {
            let todayResponse = try await actionsService.getActionsToday()
            if !todayResponse.microactions.isEmpty {
                sessionId = todayResponse.sessionId
                appPreferences.actionSessionId = todayResponse.sessionId
                actions = todayResponse.microactions.prefix(3).map { ms in
                    MicroAction(id: ms.id, title: ms.title, description: ms.description,
                                category: ms.category, difficulty: ms.difficulty,
                                estimatedMinutes: ms.estimatedMinutes, justification: ms.justification)
                }
                // Restore completed status from server
                let serverCompleted = todayResponse.microactions
                    .filter { $0.status == .completed }
                    .map(\.id)
                completedActionIDs = completedActionIDs.union(serverCompleted)
                summary = todayResponse.motivationMessage.isEmpty ? summary : todayResponse.motivationMessage
                focusArea = todayResponse.focusArea.isEmpty ? focusArea : todayResponse.focusArea
                diagnosticFirstActionID = actions.first?.id ?? "-"
                backendSyncStatusText = "Acciones cargadas (cache del día)"
                loadState = .content
                Self.debugLog("GET /actions/today OK, count=\(actions.count)")
                return
            }
        } catch {
            Self.debugLog("GET /actions/today failed or empty: \(error.localizedDescription)")
        }

        // Fallback: generate new actions
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
        return GoalMapping.mapGoals(Array(persistedGoals.prefix(3)))
    }

    // MARK: - Private: Daily State

    private func configureDailyState() {
        resetStreakIfNeededForSkippedDays()
        loadTodayCompletedActions()
        streakDays = appPreferences.streakDays
        diagnosticsVisible = appPreferences.diagnosticsVisible
        dateText = Self.dateFormatter.string(from: Date())
        sessionId = appPreferences.actionSessionId
    }

    private func resetStreakIfNeededForSkippedDays() {
        guard let lastCompletedDate = appPreferences.lastCompletedActionsDate else { return }
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
        guard completedActionIDs.count == actions.count else { return }
        let today = calendar.startOfDay(for: Date())
        let previousCompletionDate = appPreferences.lastCompletedActionsDate.map { calendar.startOfDay(for: $0) }

        if let previousCompletionDate, calendar.isDate(previousCompletionDate, inSameDayAs: today) { return }

        let previousStreak = streakDays
        if let previousCompletionDate,
           let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
           calendar.isDate(previousCompletionDate, inSameDayAs: yesterday) {
            appPreferences.streakDays += 1
        } else {
            appPreferences.streakDays = 1
        }

        appPreferences.lastCompletedActionsDate = today
        streakDays = appPreferences.streakDays

        if streakDays > previousStreak && previousStreak > 0 {
            showStreakCelebration = true
        }
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
