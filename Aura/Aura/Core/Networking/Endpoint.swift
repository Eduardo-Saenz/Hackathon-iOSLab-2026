import Foundation

struct Endpoint {
    enum Method: String {
        case get = "GET"
        case post = "POST"
        case patch = "PATCH"
        case delete = "DELETE"
    }

    let path: String
    let method: Method
    var queryItems: [URLQueryItem] = []
    var headers: [String: String] = [:]
    var body: Data?
}

extension Endpoint {
    static let health = Endpoint(path: "/health", method: .get)

    static func generateActions(body: Data) -> Endpoint {
        Endpoint(
            path: "/generate-actions",
            method: .post,
            headers: [:],
            body: body
        )
    }

    static func chat(body: Data) -> Endpoint {
        Endpoint(
            path: "/chat",
            method: .post,
            headers: [:],
            body: body
        )
    }

    // MARK: - Actions

    static let actionsToday = Endpoint(path: "/actions/today", method: .get)

    static func completeAction(sessionId: String, actionId: String) -> Endpoint {
        Endpoint(path: "/actions/\(sessionId)/microactions/\(actionId)/complete", method: .patch)
    }

    static func skipAction(sessionId: String, actionId: String) -> Endpoint {
        Endpoint(path: "/actions/\(sessionId)/microactions/\(actionId)/skip", method: .patch)
    }

    // MARK: - User

    static let usersMe = Endpoint(path: "/users/me", method: .get)

    static func patchUsersMe(body: Data) -> Endpoint {
        Endpoint(path: "/users/me", method: .patch, body: body)
    }

    static let userStreak = Endpoint(path: "/users/me/streak", method: .get)

    // MARK: - Daily Brief

    static let dailyBrief = Endpoint(path: "/daily-brief", method: .get)

    static func healthSummary(body: Data) -> Endpoint {
        Endpoint(path: "/health-summary", method: .post, body: body)
    }

    // MARK: - Emotions

    static func emotionCheckin(body: Data) -> Endpoint {
        Endpoint(path: "/emotions/checkin", method: .post, body: body)
    }

    static func emotionHistory(limit: Int = 20, offset: Int = 0) -> Endpoint {
        Endpoint(
            path: "/emotions/history",
            method: .get,
            queryItems: [
                URLQueryItem(name: "limit", value: "\(limit)"),
                URLQueryItem(name: "offset", value: "\(offset)")
            ]
        )
    }

    // MARK: - Chat Sessions

    static func chatSessions(kind: ChatSessionKind? = nil) -> Endpoint {
        Endpoint(
            path: "/chat/sessions",
            method: .get,
            queryItems: kind.map { [URLQueryItem(name: "session_kind", value: $0.rawValue)] } ?? []
        )
    }

    static func chatSessionMessages(sessionId: String) -> Endpoint {
        Endpoint(path: "/chat/sessions/\(sessionId)/messages", method: .get)
    }

    // MARK: - Auth

    static func deleteSession(body: Data) -> Endpoint {
        Endpoint(path: "/auth/session", method: .delete, body: body)
    }
}
