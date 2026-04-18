import Foundation
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published private(set) var availableGoals: [WellnessGoal] = WellnessGoal.predefined
    @Published private(set) var selectedGoalIDs: Set<String>
    @Published var isSyncing = false

    private let appPreferences: AppPreferences
    private let userService: UserServiceProtocol

    init(appPreferences: AppPreferences) {
        self.appPreferences = appPreferences
        self.selectedGoalIDs = Set(appPreferences.selectedGoalIDs)
        if Self.isRunningInPreview {
            self.userService = MockUserService()
        } else {
            self.userService = UserAPIService(apiClient: APIClient())
        }
    }

    init(appPreferences: AppPreferences, userService: UserServiceProtocol) {
        self.appPreferences = appPreferences
        self.selectedGoalIDs = Set(appPreferences.selectedGoalIDs)
        self.userService = userService
    }

    var canContinue: Bool {
        selectedGoalIDs.count >= 2 && selectedGoalIDs.count <= 3
    }

    func toggleGoal(_ goalID: String) {
        if selectedGoalIDs.contains(goalID) {
            selectedGoalIDs.remove(goalID)
            return
        }

        guard selectedGoalIDs.count < 3 else { return }
        selectedGoalIDs.insert(goalID)
    }

    /// Saves locally and syncs profile to backend.
    @discardableResult
    func completeOnboarding(name: String?, preferredTone: String?) async -> Bool {
        isSyncing = true
        defer { isSyncing = false }

        // Sync to backend (best-effort)
        let mappedGoals = GoalMapping.mapGoals(Array(selectedGoalIDs))
        let body = PatchUserBody(
            name: name,
            email: nil,
            timezone: TimeZone.current.identifier,
            preferredTone: preferredTone,
            goals: mappedGoals,
            onboardingCompleted: true
        )

        do {
            let user = try await userService.patchMe(body)
            appPreferences.selectedGoalIDs = Array(selectedGoalIDs)
            appPreferences.hasCompletedOnboarding = user.onboardingCompleted
            appPreferences.currentUserId = user.id
            appPreferences.userEmail = user.email
            if let cachedName = user.name ?? name, !cachedName.isEmpty {
                appPreferences.cachedUserName = cachedName
            }
            #if DEBUG
            print("🎓 Onboarding PATCH /users/me OK")
            #endif
            return true
        } catch {
            #if DEBUG
            print("🎓 Onboarding PATCH /users/me failed: \(error.localizedDescription)")
            #endif
            return false
        }
    }

    private static var isRunningInPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}
