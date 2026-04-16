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
}

#Preview {
    RootView(viewModel: .preview(route: .mainTabs))
}
