import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var notificationsEnabled: Bool
    @Published var diagnosticsVisible: Bool
    @Published private(set) var displayName = "Your account"
    @Published private(set) var email = "No email available"
    @Published private(set) var isLoadingProfile = false
    @Published private(set) var healthKitEnabled = false
    @Published private(set) var healthKitStatusText = "No conectado"
    @Published private(set) var availableGoals: [WellnessGoal] = WellnessGoal.predefined
    @Published private(set) var selectedGoalIDs: Set<String>
    @Published var goalSelectionErrorMessage: String?

    private let appPreferences: AppPreferences
    private let healthKitManager: HealthKitManaging
    private let userService: UserServiceProtocol

    init(appPreferences: AppPreferences) {
        self.appPreferences = appPreferences
        self.healthKitManager = HealthKitManager()
        self.userService = UserAPIService(apiClient: APIClient())
        self.notificationsEnabled = appPreferences.notificationEnabled
        self.diagnosticsVisible = appPreferences.diagnosticsVisible
        self.selectedGoalIDs = Set(appPreferences.selectedGoalIDs)
        if self.selectedGoalIDs.isEmpty {
            self.selectedGoalIDs = Set(WellnessGoal.predefined.prefix(2).map(\.id))
        }
        hydrateCachedProfile()
        refreshHealthKitStatus()
    }

    init(appPreferences: AppPreferences, healthKitManager: HealthKitManaging) {
        self.appPreferences = appPreferences
        self.healthKitManager = healthKitManager
        self.userService = UserAPIService(apiClient: APIClient())
        self.notificationsEnabled = appPreferences.notificationEnabled
        self.diagnosticsVisible = appPreferences.diagnosticsVisible
        self.selectedGoalIDs = Set(appPreferences.selectedGoalIDs)
        if self.selectedGoalIDs.isEmpty {
            self.selectedGoalIDs = Set(WellnessGoal.predefined.prefix(2).map(\.id))
        }
        hydrateCachedProfile()
        refreshHealthKitStatus()
    }

    init(appPreferences: AppPreferences, healthKitManager: HealthKitManaging, userService: UserServiceProtocol) {
        self.appPreferences = appPreferences
        self.healthKitManager = healthKitManager
        self.userService = userService
        self.notificationsEnabled = appPreferences.notificationEnabled
        self.diagnosticsVisible = appPreferences.diagnosticsVisible
        self.selectedGoalIDs = Set(appPreferences.selectedGoalIDs)
        if self.selectedGoalIDs.isEmpty {
            self.selectedGoalIDs = Set(WellnessGoal.predefined.prefix(2).map(\.id))
        }
        hydrateCachedProfile()
        refreshHealthKitStatus()
    }

    func updateNotifications(_ enabled: Bool) {
        notificationsEnabled = enabled
        appPreferences.notificationEnabled = enabled
    }

    func updateDiagnosticsVisible(_ enabled: Bool) {
        diagnosticsVisible = enabled
        appPreferences.diagnosticsVisible = enabled
    }

    func refreshHealthKitStatus() {
        healthKitManager.refreshAuthorizationState()

        switch healthKitManager.authorizationState {
        case .authorized:
            healthKitEnabled = true
            healthKitStatusText = "Conectado ✓"
        case .requesting:
            healthKitEnabled = false
            healthKitStatusText = "Conectando..."
        case .denied:
            healthKitEnabled = false
            healthKitStatusText = "Permiso denegado"
        case .unavailable:
            healthKitEnabled = false
            healthKitStatusText = "No disponible en este dispositivo"
        case .notRequested:
            healthKitEnabled = false
            healthKitStatusText = "No conectado"
        }
    }

    func loadProfile() async {
        isLoadingProfile = true
        defer { isLoadingProfile = false }

        do {
            let user = try await userService.getMe()
            displayName = user.name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                ? user.name!
                : (appPreferences.cachedUserName ?? "Your account")
            email = user.email?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                ? user.email!
                : (appPreferences.userEmail ?? "No email available")
            appPreferences.currentUserId = user.id
            appPreferences.userEmail = user.email
            if let name = user.name, !name.isEmpty {
                appPreferences.cachedUserName = name
            }
        } catch {
            hydrateCachedProfile()
        }
    }

    func setHealthKitEnabled(_ enabled: Bool) async {
        if enabled {
            await healthKitManager.requestAuthorization()
        }
        refreshHealthKitStatus()
    }

    var selectedGoalsSummary: String {
        let selectedGoals = availableGoals.filter { selectedGoalIDs.contains($0.id) }

        if selectedGoals.isEmpty {
            return "Sin metas seleccionadas"
        }

        return selectedGoals.map(\.title).joined(separator: ", ")
    }

    func isGoalSelected(_ goalID: String) -> Bool {
        selectedGoalIDs.contains(goalID)
    }

    func toggleGoalSelection(_ goalID: String) {
        goalSelectionErrorMessage = nil

        if selectedGoalIDs.contains(goalID) {
            selectedGoalIDs.remove(goalID)
            return
        }

        guard selectedGoalIDs.count < 3 else {
            goalSelectionErrorMessage = "Puedes seleccionar hasta 3 metas."
            return
        }

        selectedGoalIDs.insert(goalID)
    }

    @discardableResult
    func persistSelectedGoals() -> Bool {
        guard selectedGoalIDs.count >= 2 else {
            goalSelectionErrorMessage = "Selecciona al menos 2 metas."
            return false
        }

        appPreferences.selectedGoalIDs = Array(selectedGoalIDs)
        goalSelectionErrorMessage = nil
        return true
    }

    func restorePersistedGoals() {
        let storedIDs = Set(appPreferences.selectedGoalIDs)
        if storedIDs.isEmpty {
            selectedGoalIDs = Set(availableGoals.prefix(2).map(\.id))
        } else {
            selectedGoalIDs = storedIDs
        }
        goalSelectionErrorMessage = nil
    }

    private func hydrateCachedProfile() {
        displayName = appPreferences.cachedUserName ?? "Your account"
        email = appPreferences.userEmail ?? "No email available"
    }
}
