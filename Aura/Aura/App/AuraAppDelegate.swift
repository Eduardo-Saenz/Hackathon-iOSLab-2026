import UIKit
import GoogleSignIn

final class AuraAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        AuraGoogleConfiguration.applyIfAvailable()
        return true
    }
}
