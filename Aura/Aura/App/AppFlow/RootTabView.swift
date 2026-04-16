import SwiftUI

struct RootTabView: View {
    let onSignOut: () -> Void

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Inicio", systemImage: "house.fill")
            }

            NavigationStack {
                ProgressViewScreen()
            }
            .tabItem {
                Label("Progreso", systemImage: "chart.bar.fill")
            }

            NavigationStack {
                CoachView()
            }
            .tabItem {
                Label("Coach", systemImage: "brain.head.profile")
            }

            NavigationStack {
                SettingsView(onSignOut: onSignOut)
            }
            .tabItem {
                Label("Ajustes", systemImage: "gearshape.fill")
            }
        }
        .tint(AuraColors.primary)
    }
}

#Preview {
    RootTabView(onSignOut: {})
}
