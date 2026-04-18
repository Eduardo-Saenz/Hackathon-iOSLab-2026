import SwiftUI
import GoogleSignIn

@main
struct AuraApp: App {
    @UIApplicationDelegateAdaptor(AuraAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .onOpenURL { GIDSignIn.sharedInstance.handle($0) }
        }
    }
}
