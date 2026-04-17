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
