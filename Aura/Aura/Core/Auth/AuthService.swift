import Foundation
#if ENABLE_SIGN_IN_WITH_APPLE
import AuthenticationServices
#endif

// MARK: - Response Models

struct AuthTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
}

// MARK: - Auth Service

/// Handles all authentication API calls to AuraBE.
@MainActor
final class AuthService {
    static let shared = AuthService()

    private let baseURL = AppConfig.apiBaseURL
    private let session = URLSession.shared
    private let tokenManager = TokenManager.shared

    private init() {}

    // MARK: - Email/Password

    func register(email: String, password: String) async throws {
        let body = ["email": email.lowercased().trimmingCharacters(in: .whitespaces),
                     "password": password]
        let tokens: AuthTokenResponse = try await post(path: "/auth/email/register", body: body)
        storeTokens(tokens)
    }

    func login(email: String, password: String) async throws {
        let body = ["email": email.lowercased().trimmingCharacters(in: .whitespaces),
                     "password": password]
        let tokens: AuthTokenResponse = try await post(path: "/auth/email/login", body: body)
        storeTokens(tokens)
    }

    // MARK: - Apple Sign In

    #if ENABLE_SIGN_IN_WITH_APPLE
    func loginWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        guard let tokenData = credential.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8) else {
            throw AuthError.missingToken
        }

        let body = ["identityToken": identityToken]
        let tokens: AuthTokenResponse = try await post(path: "/auth/apple", body: body)
        storeTokens(tokens)
    }
    #endif

    // MARK: - Google Sign In

    func loginWithGoogle(idToken: String) async throws {
        let body = ["idToken": idToken]
        let tokens: AuthTokenResponse = try await post(path: "/auth/google", body: body)
        storeTokens(tokens)
    }

    // MARK: - Token Refresh

    func refreshTokens() async throws {
        guard let refreshToken = tokenManager.refreshToken else {
            throw AuthError.noRefreshToken
        }

        let body = ["refreshToken": refreshToken]
        let tokens: AuthTokenResponse = try await post(path: "/auth/refresh", body: body)
        storeTokens(tokens)
    }

    // MARK: - Sign Out

    func signOut() async {
        if let refreshToken = tokenManager.refreshToken {
            // Best-effort revoke — server returns 204 No Content
            var request = URLRequest(url: baseURL.appendingPathComponent("/auth/session"))
            request.httpMethod = "DELETE"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: ["refreshToken": refreshToken])
            _ = try? await session.data(for: request)
        }
        tokenManager.clearAll()
    }

    // MARK: - Validate Stored Session

    /// Checks if the stored access token is still valid by calling GET /users/me.
    func validateSession() async -> Bool {
        guard tokenManager.isAuthenticated else { return false }

        do {
            let _: UserMeResponse = try await get(path: "/users/me")
            return true
        } catch {
            // Try refreshing
            do {
                try await refreshTokens()
                let _: UserMeResponse = try await get(path: "/users/me")
                return true
            } catch {
                tokenManager.clearAll()
                return false
            }
        }
    }

    // MARK: - HTTP Helpers

    private func post<T: Decodable>(path: String, body: [String: String]) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func get<T: Decodable>(path: String) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = tokenManager.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func delete<T: Decodable>(path: String, body: [String: String]) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            // Try to parse error message from backend
            if let errorBody = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw AuthError.serverMessage(errorBody.error.message)
            }
            throw AuthError.httpError(httpResponse.statusCode)
        }
    }

    private func storeTokens(_ tokens: AuthTokenResponse) {
        tokenManager.accessToken = tokens.accessToken
        tokenManager.refreshToken = tokens.refreshToken
    }
}

// MARK: - Error Types

enum AuthError: LocalizedError {
    case missingToken
    case noRefreshToken
    case invalidResponse
    case httpError(Int)
    case serverMessage(String)

    var errorDescription: String? {
        switch self {
        case .missingToken:
            return "No se pudo obtener el token de autenticación."
        case .noRefreshToken:
            return "Sesión expirada. Inicia sesión de nuevo."
        case .invalidResponse:
            return "Respuesta inválida del servidor."
        case .httpError(let code):
            return "Error del servidor (\(code))."
        case .serverMessage(let msg):
            return msg
        }
    }
}

// MARK: - Helper Models

private struct APIErrorResponse: Codable {
    let error: APIErrorDetail
}

private struct APIErrorDetail: Codable {
    let code: String
    let message: String
}

private struct UserMeResponse: Codable {
    let id: String
}

private struct EmptyResponse: Codable {}
