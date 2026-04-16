import SwiftUI

@MainActor
struct GoalSelectionView: View {
    @StateObject private var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    init(onContinue: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(appPreferences: .shared))
        self.onContinue = onContinue
    }

    init(viewModel: OnboardingViewModel, onContinue: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onContinue = onContinue
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AuraSpacing.xLarge) {
                Text("PASO 1 DE 3")
                    .font(AuraTypography.caption)
                    .foregroundStyle(AuraColors.primary)
                    .padding(.horizontal, AuraSpacing.medium)
                    .padding(.vertical, AuraSpacing.small)
                    .background(AuraColors.pillBackground)
                    .clipShape(Capsule())

                VStack(alignment: .leading, spacing: AuraSpacing.small) {
                    Text("¿Qué quieres lograr hoy?")
                        .font(AuraTypography.title)
                        .foregroundStyle(AuraColors.textPrimary)

                    Text("(Selecciona tus prioridades)")
                        .font(AuraTypography.body)
                        .foregroundStyle(AuraColors.textSecondary)
                }
                .padding(.horizontal, AuraSpacing.small)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AuraSpacing.medium), count: 3), spacing: AuraSpacing.medium) {
                    ForEach(viewModel.availableGoals) { goal in
                        goalCell(goal: goal)
                    }
                }
                .padding(.horizontal, AuraSpacing.small)

                Text("\(viewModel.selectedGoalIDs.count) metas seleccionadas")
                    .font(AuraTypography.caption)
                    .foregroundStyle(AuraColors.primary)
                    .padding(.horizontal, AuraSpacing.medium)
                    .padding(.vertical, AuraSpacing.small)
                    .background(AuraColors.pillBackground)
                    .clipShape(Capsule())
                    .frame(maxWidth: .infinity, alignment: .center)

                Spacer(minLength: 0)

                Button {
                    viewModel.completeOnboarding()
                    onContinue()
                } label: {
                    Text("Siguiente")
                        .font(AuraTypography.bodyStrong)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AuraSpacing.medium)
                        .background(viewModel.canContinue ? AuraColors.primary : AuraColors.textTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: AuraCorners.medium))
                }
                .disabled(!viewModel.canContinue)
            }
            .padding(.horizontal, AuraSpacing.large)
            .padding(.vertical, AuraSpacing.xLarge)
            .background(AuraColors.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func goalCell(goal: WellnessGoal) -> some View {
        let isSelected = viewModel.selectedGoalIDs.contains(goal.id)

        return Button {
            viewModel.toggleGoal(goal.id)
        } label: {
            VStack(spacing: AuraSpacing.small) {
                Image(systemName: goal.iconName)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(isSelected ? AuraColors.primary : AuraColors.textSecondary)
                Text(goal.title)
                    .font(AuraTypography.caption)
                    .foregroundStyle(isSelected ? AuraColors.primary : AuraColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 112)
            .background(isSelected ? AuraColors.successSoft : AuraColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AuraCorners.large))
            .overlay(
                RoundedRectangle(cornerRadius: AuraCorners.large)
                    .stroke(isSelected ? AuraColors.primary.opacity(0.4) : AuraColors.cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    GoalSelectionView()
}
