import SwiftUI

@MainActor
struct GoalSelectionView: View {
    @StateObject private var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @State private var currentStep: Int = 1
    @State private var selectedTone: ToneOption?

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var age: String = ""

    private let maxGoals = 3

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
                stepPill

                Group {
                    if currentStep == 1 {
                        personalInfoStep
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                )
                            )
                    } else if currentStep == 2 {
                        goalsStep
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                )
                            )
                    } else {
                        toneStep
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                )
                            )
                    }
                }

                Spacer(minLength: 0)

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                        if currentStep < 3 {
                            currentStep += 1
                        } else {
                            // Aquí puedes guardar firstName, lastName, age y selectedTone
                            // en tu viewModel o preferences si quieres
                            viewModel.completeOnboarding()
                            onContinue()
                        }
                    }
                } label: {
                    Text(currentStep < 3 ? "Siguiente" : "Continuar")
                        .font(AuraTypography.bodyStrong)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AuraSpacing.medium)
                        .background(primaryButtonEnabled ? AuraColors.primary : AuraColors.textTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: AuraCorners.medium))
                        .shadow(
                            color: primaryButtonEnabled ? AuraColors.primary.opacity(0.3) : Color.clear,
                            radius: 8,
                            y: 4
                        )
                }
                .disabled(!primaryButtonEnabled)
            }
            .padding(.horizontal, AuraSpacing.large)
            .padding(.vertical, AuraSpacing.xLarge)
            .background(AuraColors.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .animation(.spring(response: 0.35, dampingFraction: 0.86), value: currentStep)
            .animation(.spring(response: 0.35, dampingFraction: 0.86), value: viewModel.selectedGoalIDs)
            .animation(.spring(response: 0.35, dampingFraction: 0.86), value: selectedTone)
        }
    }

    // MARK: - Step Pill

    private var stepPill: some View {
        Text("PASO \(currentStep) DE 3")
            .font(AuraTypography.caption)
            .foregroundStyle(AuraColors.primary)
            .padding(.horizontal, AuraSpacing.medium)
            .padding(.vertical, AuraSpacing.small)
            .background(AuraColors.pillBackground)
            .clipShape(Capsule())
    }

    // MARK: - Step 1

    private var personalInfoStep: some View {
        VStack(alignment: .leading, spacing: AuraSpacing.xLarge) {
            VStack(alignment: .leading, spacing: AuraSpacing.small) {
                Text("Cuéntanos sobre ti")
                    .font(AuraTypography.title)
                    .foregroundStyle(AuraColors.textPrimary)

                Text("(Completa tus datos)")
                    .font(AuraTypography.body)
                    .foregroundStyle(AuraColors.textSecondary)
            }
            .padding(.horizontal, AuraSpacing.small)

            VStack(spacing: AuraSpacing.medium) {
                onboardingField(
                    title: "Nombre",
                    placeholder: "Escribe tu nombre",
                    text: $firstName
                )

                onboardingField(
                    title: "Apellido",
                    placeholder: "Escribe tu apellido",
                    text: $lastName
                )

                onboardingNumberField(
                    title: "Edad",
                    placeholder: "Escribe tu edad",
                    text: $age
                )
            }
            .padding(.horizontal, AuraSpacing.small)
        }
    }

    private func onboardingField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: AuraSpacing.small) {
            Text(title)
                .font(AuraTypography.footnote)
                .foregroundStyle(AuraColors.textSecondary)

            TextField(placeholder, text: text)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .font(AuraTypography.body)
                .foregroundStyle(AuraColors.textSecondary)
                .padding(.horizontal, AuraSpacing.medium)
                .padding(.vertical, AuraSpacing.smedium)
                .background(AuraColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AuraCorners.medium))
                .shadow(color: AuraColors.shadowCool.opacity(0.6), radius: 8, y: 3)
        }
    }

    private func onboardingNumberField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: AuraSpacing.small) {
            Text(title)
                .font(AuraTypography.footnote)
                .foregroundStyle(AuraColors.textSecondary)

            TextField(placeholder, text: text)
                .keyboardType(.numberPad)
                .font(AuraTypography.body)
                .foregroundStyle(AuraColors.textSecondary)
                .padding(.horizontal, AuraSpacing.medium)
                .padding(.vertical, AuraSpacing.smedium)
                .background(AuraColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AuraCorners.medium))
                .shadow(color: AuraColors.shadowCool.opacity(0.6), radius: 8, y: 3)
                .onChange(of: age) { newValue in
                    age = newValue.filter { $0.isNumber }
                }
        }
    }

    // MARK: - Step 2

    private var goalsStep: some View {
        VStack(alignment: .leading, spacing: AuraSpacing.xLarge) {
            VStack(alignment: .leading, spacing: AuraSpacing.small) {
                Text("¿Qué quieres lograr hoy?")
                    .font(AuraTypography.title)
                    .foregroundStyle(AuraColors.textPrimary)

                Text("(Selecciona tus prioridades)")
                    .font(AuraTypography.body)
                    .foregroundStyle(AuraColors.textSecondary)
            }
            .padding(.horizontal, AuraSpacing.small)

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: AuraSpacing.medium),
                    count: 3
                ),
                spacing: AuraSpacing.medium
            ) {
                ForEach(viewModel.availableGoals) { goal in
                    goalCell(goal: goal)
                }
            }
            .padding(.horizontal, AuraSpacing.small)

            Text("\(viewModel.selectedGoalIDs.count) de \(maxGoals) metas seleccionadas")
                .font(AuraTypography.caption)
                .foregroundStyle(AuraColors.primary)
                .padding(.horizontal, AuraSpacing.medium)
                .padding(.vertical, AuraSpacing.small)
                .background(AuraColors.pillBackground)
                .clipShape(Capsule())
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private func goalCell(goal: WellnessGoal) -> some View {
        let isSelected = viewModel.selectedGoalIDs.contains(goal.id)
        let limitReached = viewModel.selectedGoalIDs.count >= maxGoals
        let shouldPushBack = limitReached && !isSelected

        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                if isSelected {
                    viewModel.toggleGoal(goal.id)
                } else if viewModel.selectedGoalIDs.count < maxGoals {
                    viewModel.toggleGoal(goal.id)
                }
            }
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
            .shadow(color: isSelected ? Color.clear : AuraColors.shadowCool, radius: 8, y: 3)
            .overlay(
                RoundedRectangle(cornerRadius: AuraCorners.large)
                    .stroke(isSelected ? AuraColors.primary.opacity(0.4) : Color.clear, lineWidth: 2)
            )
            .scaleEffect(shouldPushBack ? 0.92 : 1.0)
            .offset(y: shouldPushBack ? 6 : 0)
            .opacity(shouldPushBack ? 0.65 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(limitReached && !isSelected)
    }

    // MARK: - Step 3

    private var toneStep: some View {
        VStack(alignment: .leading, spacing: AuraSpacing.xLarge) {
            VStack(alignment: .leading, spacing: AuraSpacing.small) {
                Text("¿En qué tono quieres que te hable?")
                    .font(AuraTypography.title)
                    .foregroundStyle(AuraColors.textPrimary)

                Text("(Elige una opción)")
                    .font(AuraTypography.body)
                    .foregroundStyle(AuraColors.textSecondary)
            }
            .padding(.horizontal, AuraSpacing.small)

            VStack(spacing: AuraSpacing.medium) {
                ForEach(ToneOption.allCases, id: \.self) { tone in
                    toneCell(tone: tone)
                }
            }
            .padding(.horizontal, AuraSpacing.small)
        }
    }

    private func toneCell(tone: ToneOption) -> some View {
        let isSelected = selectedTone == tone
        let hasSelection = selectedTone != nil
        let shouldPushBack = hasSelection && !isSelected

        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                selectedTone = tone
            }
        } label: {
            VStack(spacing: AuraSpacing.xSmall) {
                Text(tone.title)
                    .font(AuraTypography.bodyStrong)
                    .foregroundStyle(isSelected ? AuraColors.primary : AuraColors.textPrimary)

                Text(tone.subtitle)
                    .font(AuraTypography.caption)
                    .foregroundStyle(isSelected ? AuraColors.primary.opacity(0.7) : AuraColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AuraSpacing.medium)
            .background(isSelected ? AuraColors.successSoft : AuraColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AuraCorners.medium))
            .shadow(color: isSelected ? Color.clear : AuraColors.shadowCool, radius: 8, y: 3)
            .overlay(
                RoundedRectangle(cornerRadius: AuraCorners.medium)
                    .stroke(isSelected ? AuraColors.primary.opacity(0.4) : Color.clear, lineWidth: 2)
            )
            .scaleEffect(shouldPushBack ? 0.97 : 1.0)
            .offset(y: shouldPushBack ? 4 : 0)
            .opacity(shouldPushBack ? 0.7 : 1.0)
        }
        .buttonStyle(.plain)
    }

    // MARK: - State

    private var primaryButtonEnabled: Bool {
        switch currentStep {
        case 1:
            return !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !age.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 2:
            return !viewModel.selectedGoalIDs.isEmpty
        case 3:
            return selectedTone != nil
        default:
            return false
        }
    }
}

// MARK: - Tone Option

private enum ToneOption: String, CaseIterable {
    case calmado = "Calmado"
    case motivacional = "Motivacional"
    case normal = "Normal"

    var title: String { rawValue }

    var subtitle: String {
        switch self {
        case .calmado:
            return "Mensajes tranquilos, sin presión"
        case .motivacional:
            return "Inspirador, con energía para avanzar"
        case .normal:
            return "Información concisa"
        }
    }
}

#Preview {
    GoalSelectionView()
}
