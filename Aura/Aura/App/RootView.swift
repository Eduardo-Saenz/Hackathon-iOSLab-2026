import SwiftUI

@MainActor
struct RootView: View {
    @StateObject private var viewModel: AppFlowViewModel

    init() {
        _viewModel = StateObject(wrappedValue: AppFlowViewModel(appPreferences: .shared))
    }

    init(viewModel: AppFlowViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    @State private var splashFinished = false

    var body: some View {
        ZStack {
            if !splashFinished || viewModel.isCheckingSession {
                AuraSplashView {
                    withAnimation(AuraAnimations.silkTransition) {
                        splashFinished = true
                    }
                }
                .transition(.opacity)
                .zIndex(1)
            }
            
            if splashFinished && !viewModel.isCheckingSession {
                Group {
                    switch viewModel.route {
                    case .auth:
                        LoginView {
                            viewModel.handleAuthSuccess()
                        }
                    case .onboarding:
                        GoalSelectionView {
                            viewModel.handleOnboardingComplete()
                        }
                    case .mainTabs:
                        RootTabView {
                            viewModel.signOut()
                        }
                    }
                }
                .transition(.asymmetric(insertion: .identity, removal: .opacity))
            }
        }
        .task {
            await viewModel.validateStoredSession()
        }
    }
}

#Preview {
    RootView(viewModel: .preview(route: .mainTabs))
}
