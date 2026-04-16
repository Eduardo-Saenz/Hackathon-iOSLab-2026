import Foundation

struct Endpoint {
    enum Method: String {
        case get = "GET"
        case post = "POST"
    }

    let path: String
    let method: Method
    var queryItems: [URLQueryItem] = []
    var headers: [String: String] = [:]
    var body: Data?
}
