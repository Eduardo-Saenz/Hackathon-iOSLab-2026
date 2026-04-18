import Foundation
import GoogleSignIn

/// Configures the Google Sign-In SDK from `GoogleService-Info.plist` (if present) or `GOOGLE_CLIENT_ID` in the scheme environment.
enum AuraGoogleConfiguration {
    static func applyIfAvailable() {
        if GIDSignIn.sharedInstance.configuration != nil { return }

        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
           let clientId = dict["CLIENT_ID"] as? String,
           !clientId.isEmpty,
           !clientId.localizedCaseInsensitiveContains("YOUR_") {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
            return
        }

        if let clientId = AppConfig.googleClientID,
           !clientId.isEmpty,
           !clientId.localizedCaseInsensitiveContains("REPLACE") {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        }
    }
}
