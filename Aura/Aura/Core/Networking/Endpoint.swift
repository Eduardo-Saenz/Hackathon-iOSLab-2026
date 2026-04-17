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
}
