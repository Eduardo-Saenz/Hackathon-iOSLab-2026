import SwiftUI

@MainActor
struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @State private var darkModeEnabled = false
    @State private var isShowingGoalsSheet = false
    let onSignOut: () -> Void

    init(onSignOut: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(appPreferences: .shared))
        self.onSignOut = onSignOut
    }

    init(viewModel: SettingsViewModel, onSignOut: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSignOut = onSignOut
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AuraSpacing.large) {
                VStack(alignment: .leading, spacing: AuraSpacing.xSmall) {
                    Text("Ajustes ⚙️")
                        .font(AuraTypography.title2)
                        .foregroundStyle(AuraColors.textPrimary)
                    Text("Personaliza tu experiencia")
                        .font(AuraTypography.body)
                        .foregroundStyle(AuraColors.textSecondary)
                }

                profileCard

                sectionTitle("PREFERENCIAS")
                VStack(spacing: 0) {
                    settingsRow(
                        icon: "bell",
                        title: "Notificaciones",
                        subtitle: "Recordatorios y logros",
                        trailing: AnyView(
                            Toggle("", isOn: Binding(
                                get: { viewModel.notificationsEnabled },
                                set: { viewModel.updateNotifications($0) }
                            ))
                            .labelsHidden()
                            .tint(AuraColors.primary)
                        )
                    )

                    Divider().padding(.leading, 54)

                    settingsRow(
                        icon: "moon",
                        title: "Modo Oscuro",
                        subtitle: "Tema de la aplicación",
                        trailing: AnyView(
                            Toggle("", isOn: $darkModeEnabled)
                                .labelsHidden()
                                .tint(AuraColors.primary)
                        )
                    )

                    Divider().padding(.leading, 54)

                    settingsRow(
                        icon: "ladybug",
                        title: "Modo diagnóstico",
                        subtitle: "Muestra logs técnicos en Home",
                        trailing: AnyView(
                            Toggle("", isOn: Binding(
                                get: { viewModel.diagnosticsVisible },
                                set: { viewModel.updateDiagnosticsVisible($0) }
                            ))
                            .labelsHidden()
                            .tint(AuraColors.primary)
                        )
                    )
                }
                .cardStyle()

                sectionTitle("SALUD & DATOS")
                VStack(spacing: 0) {
                    settingsRow(
                        icon: "heart",
                        title: "Apple HealthKit",
                        subtitle: viewModel.healthKitStatusText,
                        trailing: AnyView(
                            Toggle("", isOn: Binding(
                                get: { viewModel.healthKitEnabled },
                                set: { enabled in
                                    Task {
                                        await viewModel.setHealthKitEnabled(enabled)
                                    }
                                }
                            ))
                                .labelsHidden()
                                .tint(AuraColors.primary)
                        )
                    )

                    Divider().padding(.leading, 54)

                    Button {
                        isShowingGoalsSheet = true
                    } label: {
                        settingsRow(
                            icon: "bolt",
                            title: "Metas de bienestar",
                            subtitle: viewModel.selectedGoalsSummary,
                            trailing: AnyView(Image(systemName: "chevron.right").foregroundStyle(AuraColors.textTertiary))
                        )
                    }
                    .buttonStyle(.plain)
                }
                .cardStyle()

                sectionTitle("CUENTA")
                VStack(spacing: 0) {
                    settingsRow(
                        icon: "shield",
                        title: "Privacidad",
                        subtitle: "Gestionar tus datos",
                        trailing: AnyView(Image(systemName: "chevron.right").foregroundStyle(AuraColors.textTertiary))
                    )
                }
                .cardStyle()

                Button("Cerrar sesión", role: .destructive) {
                    onSignOut()
                }
                .font(AuraTypography.bodyStrong)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AuraSpacing.medium)
                .background(AuraColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AuraCorners.medium))
            }
            .padding(AuraSpacing.large)
        }
        .background(AuraColors.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            viewModel.refreshHealthKitStatus()
        }
        .sheet(isPresented: $isShowingGoalsSheet) {
            WellnessGoalsSelectionSheet(viewModel: viewModel)
        }
    }

    private var profileCard: some View {
        HStack(spacing: AuraSpacing.medium) {
            RoundedRectangle(cornerRadius: AuraCorners.large)
                .fill(
                    LinearGradient(
                        colors: [AuraColors.primary.opacity(0.7), AuraColors.secondary.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 78, height: 78)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white.opacity(0.9))
                )

            VStack(alignment: .leading, spacing: AuraSpacing.xSmall) {
                Text("Edu García")
                    .font(AuraTypography.headline)
                    .foregroundStyle(AuraColors.textPrimary)
                Text("edu@gmail.com")
                    .font(AuraTypography.body)
                    .foregroundStyle(AuraColors.textSecondary)
                Text("✦ Plan Premium")
                    .font(AuraTypography.footnote)
                    .foregroundStyle(AuraColors.secondary)
                    .padding(.horizontal, AuraSpacing.small)
                    .padding(.vertical, AuraSpacing.xSmall)
                    .background(AuraColors.surfaceMuted)
                    .clipShape(Capsule())
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(AuraColors.textTertiary)
        }
        .padding(AuraSpacing.medium)
        .cardStyle()
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(AuraTypography.caption)
            .foregroundStyle(AuraColors.textSecondary)
    }

    private func settingsRow(icon: String, title: String, subtitle: String, trailing: AnyView) -> some View {
        HStack(spacing: AuraSpacing.medium) {
            Circle()
                .fill(AuraColors.surfaceMuted)
                .frame(width: 38, height: 38)
                .overlay(
                    Image(systemName: icon)
                        .foregroundStyle(AuraColors.textPrimary.opacity(0.8))
                )

            VStack(alignment: .leading, spacing: AuraSpacing.xSmall) {
                Text(title)
                    .font(AuraTypography.bodyStrong)
                    .foregroundStyle(AuraColors.textPrimary)
                Text(subtitle)
                    .font(AuraTypography.footnote)
                    .foregroundStyle(AuraColors.textSecondary)
            }
            Spacer()
            trailing
        }
        .padding(AuraSpacing.medium)
    }
}

private struct WellnessGoalsSelectionSheet: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Selecciona 2-3 metas") {
                    ForEach(viewModel.availableGoals) { goal in
                        Button {
                            viewModel.toggleGoalSelection(goal.id)
                        } label: {
                            HStack(spacing: AuraSpacing.medium) {
                                Image(systemName: goal.iconName)
                                    .foregroundStyle(AuraColors.primary)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: AuraSpacing.xSmall) {
                                    Text(goal.title)
                                        .font(AuraTypography.bodyStrong)
                                        .foregroundStyle(AuraColors.textPrimary)
                                    Text(goal.subtitle)
                                        .font(AuraTypography.footnote)
                                        .foregroundStyle(AuraColors.textSecondary)
                                }

                                Spacer()

                                if viewModel.isGoalSelected(goal.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AuraColors.primary)
                                }
                            }
                            .padding(.vertical, AuraSpacing.xSmall)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let error = viewModel.goalSelectionErrorMessage {
                    Section {
                        Text(error)
                            .font(AuraTypography.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Metas de bienestar")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        viewModel.restorePersistedGoals()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        if viewModel.persistSelectedGoals() {
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                viewModel.restorePersistedGoals()
            }
        }
    }
}

private extension View {
    func cardStyle() -> some View {
        self
            .background(AuraColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AuraCorners.large))
            .overlay(
                RoundedRectangle(cornerRadius: AuraCorners.large)
                    .stroke(AuraColors.cardStroke, lineWidth: 1)
            )
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
