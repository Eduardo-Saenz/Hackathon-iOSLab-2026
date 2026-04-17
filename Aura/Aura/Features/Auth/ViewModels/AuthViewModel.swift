import Foundation
import Combine
import AuthenticationServices

@MainActor
final class AuthViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var isSignUpMode = false

    private let authService = AuthService.shared
    private let appPreferences: AppPreferences

    var onAuthSuccess: (() -> Void)?

    init(appPreferences: AppPreferences) {
        self.appPreferences = appPreferences
    }

    // MARK: - Email/Password

    func signInWithEmail(email: String, password: String) async {
        guard validateFields(email: email, password: password) else { return }

        isLoading = true
        errorMessage = nil

        do {
            if isSignUpMode {
                try await authService.register(email: email, password: password)
            } else {
                try await authService.login(email: email, password: password)
            }
            appPreferences.isAuthenticated = true
            appPreferences.userEmail = email.lowercased().trimmingCharacters(in: .whitespaces)
            onAuthSuccess?()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Apple Sign In

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = nil

        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Credencial de Apple inválida."
                isLoading = false
                return
            }

            do {
                try await authService.loginWithApple(credential: credential)
                appPreferences.isAuthenticated = true
                if let email = credential.email {
                    appPreferences.userEmail = email
                }
                onAuthSuccess?()
            } catch {
                errorMessage = error.localizedDescription
            }

        case .failure(let error):
            // User cancelled — don't show error
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
                isLoading = false
                return
            }
            errorMessage = "Error con Apple: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Google Sign In (placeholder — requires GoogleSignIn SDK)

    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil

        // Google Sign-In requires the GoogleSignIn SDK added via SPM in Xcode.
        // For now, show a message. Once the SDK is added on a Mac, replace this
        // with the real GoogleSignIn flow that gets an idToken.
        errorMessage = "Google Sign-In requiere configurar el SDK en Xcode (Mac). Usa email o Apple por ahora."

        isLoading = false
    }

    // MARK: - Sign Out

    func signOut() async {
        await authService.signOut()
        appPreferences.isAuthenticated = false
        appPreferences.hasCompletedOnboarding = false
    }

    // MARK: - Validation

    private func validateFields(email: String, password: String) -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)

        if trimmedEmail.isEmpty {
            errorMessage = "Ingresa tu correo electrónico."
            return false
        }

        if !trimmedEmail.contains("@") || !trimmedEmail.contains(".") {
            errorMessage = "Correo electrónico inválido."
            return false
        }

        if password.count < 6 {
            errorMessage = "La contraseña debe tener al menos 6 caracteres."
            return false
        }

        return true
    }
}
