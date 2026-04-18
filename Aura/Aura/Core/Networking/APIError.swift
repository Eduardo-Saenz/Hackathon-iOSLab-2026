import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingFailed(reason: String, responseBody: String?)
    case serverError(statusCode: Int, responseBody: String?)
    case transportError(String)
    case notImplemented

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL was invalid."
        case .invalidResponse:
            return "The server response was invalid."
        case let .decodingFailed(reason, responseBody):
            let body = responseBody?.isEmpty == false ? " Body: \(responseBody!)" : ""
            return "Failed to decode response. \(reason).\(body)"
        case let .serverError(statusCode, responseBody):
            let body = responseBody?.isEmpty == false ? " Body: \(responseBody!)" : ""
            return "Server error (\(statusCode)).\(body)"
        case let .transportError(message):
            return "Network transport error: \(message)"
        case .notImplemented:
            return "This API call is not implemented yet."
        }
    }
}
