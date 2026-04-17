import Foundation

protocol APIClientProtocol {
    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}

struct APIClient: APIClientProtocol {
    let baseURL: URL
    let session: URLSession

    init(baseURL: URL = AppConfig.apiBaseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }

        let normalizedPath: String
        if endpoint.path.hasPrefix("/") {
            normalizedPath = endpoint.path
        } else {
            normalizedPath = "/" + endpoint.path
        }
        components.path = normalizedPath
        components.queryItems = endpoint.queryItems.isEmpty ? nil : endpoint.queryItems

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if endpoint.body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        // Inject auth token if available
        if let token = TokenManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        endpoint.headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        #if DEBUG
        print("🌐 API Request -> \(request.httpMethod ?? "N/A") \(url.absoluteString)")
        if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            print("📦 API Request Body -> \(bodyString)")
        }
        #endif

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            #if DEBUG
            print("❌ API Transport Error -> \(error.localizedDescription)")
            #endif
            throw APIError.transportError(error.localizedDescription)
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        #if DEBUG
        print("📡 API Response Status -> \(httpResponse.statusCode)")
        #endif
        guard (200 ... 299).contains(httpResponse.statusCode) else {
            let responseBody = String(data: data, encoding: .utf8)
            #if DEBUG
            print("❌ API Server Error Body -> \(responseBody ?? "<empty>")")
            #endif
            throw APIError.serverError(statusCode: httpResponse.statusCode, responseBody: responseBody)
        }

        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)
        } catch {
            let responseBody = String(data: data, encoding: .utf8)
            #if DEBUG
            print("❌ API Decoding Error -> \(error.localizedDescription)")
            print("❌ API Decoding Body -> \(responseBody ?? "<empty>")")
            #endif
            throw APIError.decodingFailed(reason: error.localizedDescription, responseBody: responseBody)
        }
    }
}
