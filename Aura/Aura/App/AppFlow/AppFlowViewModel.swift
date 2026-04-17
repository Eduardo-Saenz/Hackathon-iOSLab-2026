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

    // MARK: - Init

    init(appPreferences: AppPreferences) {
        self.appPreferences = appPreferences

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

    // MARK: - Session Validation

    /// Call on app launch to validate stored tokens against the backend.
    func validateStoredSession() async {
        guard tokenManager.isAuthenticated else {
            isCheckingSession = false
            return
        }

        isCheckingSession = true
        let valid = await authService.validateSession()

        if valid {
            appPreferences.isAuthenticated = true
            route = appPreferences.hasCompletedOnboarding ? .mainTabs : .onboarding
        } else {
            appPreferences.isAuthenticated = false
            route = .auth
        }
        isCheckingSession = false
    }

    // MARK: - Actions

    func handleAuthSuccess() {
        appPreferences.isAuthenticated = true
        route = appPreferences.hasCompletedOnboarding ? .mainTabs : .onboarding
    }

    func handleOnboardingComplete() {
        appPreferences.hasCompletedOnboarding = true
        route = .mainTabs
    }

    func signOut() {
        Task {
            await authService.signOut()
            appPreferences.isAuthenticated = false
            route = .auth
        }
    }
}

extension AppFlowViewModel {
    static func preview(route: AppRoute) -> AppFlowViewModel {
        let preferences = AppPreferences(defaults: UserDefaults(suiteName: "PreviewDefaults") ?? .standard)
        let viewModel = AppFlowViewModel(appPreferences: preferences)
        viewModel.route = route
        return viewModel
    }
}
