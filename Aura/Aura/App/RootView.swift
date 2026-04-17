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

    var body: some View {
        Group {
            if viewModel.isCheckingSession {
                // Brief splash while validating stored session
                ZStack {
                    AuraColors.background.ignoresSafeArea()
                    VStack(spacing: AuraSpacing.medium) {
                        Text("Aura")
                            .font(AuraTypography.hero)
                            .foregroundStyle(AuraColors.textPrimary)
                        ProgressView()
                            .tint(AuraColors.primary)
                    }
                }
            } else {
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
        }
        .task {
            await viewModel.validateStoredSession()
        }
    }
}

#Preview {
    RootView(viewModel: .preview(route: .mainTabs))
}
