import Foundation
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published private(set) var availableGoals: [WellnessGoal] = WellnessGoal.predefined
    @Published private(set) var selectedGoalIDs: Set<String>

    private let appPreferences: AppPreferences

    init(appPreferences: AppPreferences) {
        self.appPreferences = appPreferences
        self.selectedGoalIDs = Set(appPreferences.selectedGoalIDs)
    }

    var canContinue: Bool {
        selectedGoalIDs.count >= 2 && selectedGoalIDs.count <= 3
    }

    func toggleGoal(_ goalID: String) {
        if selectedGoalIDs.contains(goalID) {
            selectedGoalIDs.remove(goalID)
            return
        }

        guard selectedGoalIDs.count < 3 else { return }
        selectedGoalIDs.insert(goalID)
    }

    func completeOnboarding() {
        appPreferences.selectedGoalIDs = Array(selectedGoalIDs)
        appPreferences.hasCompletedOnboarding = true
    }
}
