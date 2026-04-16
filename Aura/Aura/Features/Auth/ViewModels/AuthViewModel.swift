import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let appPreferences: AppPreferences

    init(appPreferences: AppPreferences) {
        self.appPreferences = appPreferences
    }

    func signInWithApple() async {
        await simulateSignIn()
    }

    func signInWithGoogle() async {
        await simulateSignIn()
    }

    private func simulateSignIn() async {
        isLoading = true
        errorMessage = nil
        try? await Task.sleep(nanoseconds: 300_000_000)
        appPreferences.isAuthenticated = true
        isLoading = false
    }
}
