import Foundation
import Combine

@MainActor
final class AppFlowViewModel: ObservableObject {
    // MARK: - State

    @Published private(set) var route: AppRoute

    // MARK: - Dependencies

    private let appPreferences: AppPreferences

    // MARK: - Init

    init(appPreferences: AppPreferences) {
        self.appPreferences = appPreferences

        if !appPreferences.isAuthenticated {
            route = .auth
        } else if !appPreferences.hasCompletedOnboarding {
            route = .onboarding
        } else {
            route = .mainTabs
        }
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
        appPreferences.isAuthenticated = false
        route = .auth
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
