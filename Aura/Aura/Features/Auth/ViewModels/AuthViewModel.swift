import Foundation
import Combine
#if ENABLE_SIGN_IN_WITH_APPLE
import AuthenticationServices
#endif
import UIKit
import GoogleSignIn

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

    #if ENABLE_SIGN_IN_WITH_APPLE
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
    #endif

    // MARK: - Google Sign In

    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        AuraGoogleConfiguration.applyIfAvailable()

        guard GIDSignIn.sharedInstance.configuration != nil else {
            errorMessage =
                "Google Sign-In: define GOOGLE_CLIENT_ID en el scheme de Xcode, o añade GoogleService-Info.plist (copia desde GoogleService-Info.plist.example). El backend debe usar el mismo GOOGLE_CLIENT_ID."
            return
        }

        guard let presenter = Self.presentingViewController() else {
            errorMessage = "No se pudo abrir el inicio de sesión de Google."
            return
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Google no devolvió idToken. Revisa el cliente OAuth iOS en Google Cloud."
                return
            }

            try await authService.loginWithGoogle(idToken: idToken)
            appPreferences.isAuthenticated = true
            if let email = result.user.profile?.email {
                appPreferences.userEmail = email
            }
            onAuthSuccess?()
        } catch {
            let nsError = error as NSError
            // kGIDSignInErrorDomain / GIDSignInErrorCode are not always visible to Swift; match NSError from the SDK.
            if nsError.domain == "com.google.GIDSignIn", nsError.code == -5 {
                return
            }
            errorMessage = error.localizedDescription
        }
    }

    private static func presentingViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first(where: { $0.activationState == .foregroundActive })
                ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
                ?? scene.windows.first?.rootViewController else {
            return nil
        }
        return topViewController(from: root)
    }

    private static func topViewController(from root: UIViewController) -> UIViewController {
        if let presented = root.presentedViewController {
            return topViewController(from: presented)
        }
        if let nav = root as? UINavigationController, let visible = nav.visibleViewController {
            return topViewController(from: visible)
        }
        if let tab = root as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(from: selected)
        }
        return root
    }

    // MARK: - Sign Out

    func signOut() async {
        await authService.signOut()
        appPreferences.isAuthenticated = false
        appPreferences.clearUserScopedState()
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
