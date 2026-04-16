import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingFailed
    case serverError(statusCode: Int)
    case notImplemented

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL was invalid."
        case .invalidResponse:
            return "The server response was invalid."
        case .decodingFailed:
            return "Failed to decode the server response."
        case let .serverError(statusCode):
            return "Server error (\(statusCode))."
        case .notImplemented:
            return "This API call is not implemented yet."
        }
    }
}
