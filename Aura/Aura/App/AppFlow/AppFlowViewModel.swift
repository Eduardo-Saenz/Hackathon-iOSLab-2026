import Foundation
import Combine

@MainActor
final class AppFlowViewModel: ObservableObject {
    // MARK: - State

    @Published private(set) var route: AppRoute
    @Published private(set) var isCheckingSession = true

    // MARK: - Dependencies

    private let appPreferences: AppPreferences
    private let authService = AuthService.shared
    private let tokenManager = TokenManager.shared
    private let userService: UserServiceProtocol

    // MARK: - Init

    init(appPreferences: AppPreferences) {
        self.appPreferences = appPreferences
        self.userService = UserAPIService(apiClient: APIClient())

        // Start on auth while we validate the session
        if !appPreferences.isAuthenticated && !tokenManager.isAuthenticated {
            route = .auth
            isCheckingSession = false
        } else if !appPreferences.hasCompletedOnboarding {
            route = .onboarding
            isCheckingSession = false
        } else {
            route = .mainTabs
            isCheckingSession = false
        }
    }

    init(appPreferences: AppPreferences, userService: UserServiceProtocol) {
        self.appPreferences = appPreferences
        self.userService = userService

        if !appPreferences.isAuthenticated && !tokenManager.isAuthenticated {
            route = .auth
            isCheckingSession = false
        } else if !appPreferences.hasCompletedOnboarding {
            route = .onboarding
            isCheckingSession = false
        } else {
            route = .mainTabs
            isCheckingSession = false
        }
    }

    // MARK: - Session Validation

    /// Call on app launch to validate stored tokens against the backend.
    func validateStoredSession() async {
        guard tokenManager.isAuthenticated else {
            appPreferences.clearUserScopedState()
            isCheckingSession = false
            route = .auth
            return
        }

        isCheckingSession = true
        let valid = await authService.validateSession()

        if valid {
            appPreferences.isAuthenticated = true
            await hydrateCurrentUser()
        } else {
            appPreferences.clearUserScopedState()
            appPreferences.isAuthenticated = false
            route = .auth
        }
        isCheckingSession = false
    }

    // MARK: - Actions

    func handleAuthSuccess() {
        appPreferences.isAuthenticated = true
        isCheckingSession = true
        Task {
            await hydrateCurrentUser()
            isCheckingSession = false
        }
    }

    func handleOnboardingComplete() {
        appPreferences.hasCompletedOnboarding = true
        route = .mainTabs
    }

    func signOut() {
        Task {
            await authService.signOut()
            appPreferences.clearUserScopedState()
            appPreferences.isAuthenticated = false
            route = .auth
        }
    }

    private func hydrateCurrentUser() async {
        do {
            let user = try await userService.getMe()
            applyUserState(user)
        } catch {
            appPreferences.clearUserScopedState()
            appPreferences.isAuthenticated = false
            route = .auth
        }
    }

    private func applyUserState(_ user: UserMe) {
        let previousUserId = appPreferences.currentUserId
        if let previousUserId, previousUserId != user.id {
            appPreferences.clearUserScopedState()
        }

        appPreferences.currentUserId = user.id
        appPreferences.userEmail = user.email
        if let name = user.name, !name.isEmpty {
            appPreferences.cachedUserName = name
        }
        appPreferences.hasCompletedOnboarding = user.onboardingCompleted
        let localGoalIDs = GoalMapping.mapFromBackendGoals(user.goals)
        if !localGoalIDs.isEmpty {
            appPreferences.selectedGoalIDs = localGoalIDs
        }
        route = user.onboardingCompleted ? .mainTabs : .onboarding
    }
}

extension AppFlowViewModel {
    static func preview(route: AppRoute) -> AppFlowViewModel {
        let preferences = AppPreferences(defaults: UserDefaults(suiteName: "PreviewDefaults") ?? .standard)
        let viewModel = AppFlowViewModel(appPreferences: preferences, userService: MockUserService())
        viewModel.route = route
        return viewModel
    }
}
