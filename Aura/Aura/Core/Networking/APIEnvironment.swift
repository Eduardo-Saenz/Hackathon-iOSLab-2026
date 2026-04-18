import Foundation

struct APIEnvironment {
    let baseURL: URL

    static var current: APIEnvironment {
        #if targetEnvironment(simulator)
        return APIEnvironment(baseURL: URL(string: "http://localhost:3000")!)
        #else
        return APIEnvironment(baseURL: URL(string: "https://api.example.com")!)
        #endif
    }
}
