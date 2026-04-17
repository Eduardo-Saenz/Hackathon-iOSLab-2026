import Foundation

enum AppConfig {
    /// Base URL for the AuraBE API.
    /// Set via Xcode scheme environment variable `API_BASE_URL`,
    /// or defaults to localhost for simulator development.
    static let apiBaseURL: URL = {
        if let envURL = ProcessInfo.processInfo.environment["API_BASE_URL"],
           let url = URL(string: envURL) {
            return url
        }
        // Default: localhost for simulator, adjust for device
        return URL(string: "http://localhost:3000")!
    }()

    /// Apple Bundle ID for Sign In with Apple verification.
    /// Must match APPLE_BUNDLE_ID on the backend.
    static let appleBundleID = Bundle.main.bundleIdentifier ?? "me.cecigaona.Aura"

    /// Google OAuth Client ID for iOS (set in Xcode scheme or Info.plist).
    static let googleClientID: String? = {
        ProcessInfo.processInfo.environment["GOOGLE_CLIENT_ID"]
            ?? Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") as? String
    }()
}
