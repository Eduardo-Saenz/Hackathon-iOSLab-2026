import SwiftUI
import Foundation

@MainActor
struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel

    init() {
        _viewModel = StateObject(wrappedValue: HomeViewModel())
    }

    init(viewModel: HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AuraSpacing.large) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: AuraSpacing.xSmall) {
                        Text(viewModel.greeting)
                            .font(AuraTypography.title2)
                            .foregroundStyle(AuraColors.textPrimary)
                        Text(viewModel.dateText)
                            .font(AuraTypography.caption)
                            .foregroundStyle(AuraColors.textSecondary)
                    }

                    Spacer()

                    HStack(spacing: AuraSpacing.small) {
                        statPill(text: "🔥\(viewModel.streakDays)", background: AuraColors.orangeSoft, foreground: AuraColors.tertiary)
                        statPill(text: "\(viewModel.completedCount)/\(viewModel.actions.count)", background: AuraColors.blueSoft, foreground: AuraColors.secondary)
                    }
                }

                Capsule()
                    .fill(AuraColors.surfaceMuted)
                    .frame(height: 28)
                    .overlay(
                        Text(viewModel.healthStatusText)
                            .font(AuraTypography.caption)
                            .foregroundStyle(AuraColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, AuraSpacing.medium)
                    )

                VStack(alignment: .leading, spacing: AuraSpacing.medium) {
                    Text("TU RESUMEN DE HOY")
                        .font(AuraTypography.caption)
                        .foregroundStyle(AuraColors.textSecondary)

                    HStack(spacing: AuraSpacing.medium) {
                        metricCard(value: stepsText, unit: "PASOS", background: AuraColors.successSoft, foreground: AuraColors.primary)
                        metricCard(value: sleepText, unit: "h SUEÑO", background: AuraColors.blueSoft, foreground: AuraColors.secondary)
                        metricCard(value: caloriesText, unit: "kcal ACTIVAS", background: AuraColors.orangeSoft, foreground: AuraColors.tertiary)
                    }
                }

                VStack(alignment: .leading, spacing: AuraSpacing.smedium) {
                    HStack(spacing: AuraSpacing.small) {
                        Text("🤖  TU COACH DICE...")
                            .font(AuraTypography.caption)
                            .foregroundStyle(AuraColors.secondary)
                    }
                    Text("\"\(viewModel.summary)\"")
                        .font(AuraTypography.bodyStrong)
                        .foregroundStyle(AuraColors.textPrimary)
                    HStack(spacing: AuraSpacing.small) {
                        Image(systemName: "waveform.path.ecg")
                            .foregroundStyle(AuraColors.primary)
                        Text("Analizando tus datos de salud...")
                            .font(AuraTypography.footnote)
                            .foregroundStyle(AuraColors.textSecondary)
                    }
                }
                .padding(AuraSpacing.medium)
                .background(
                    LinearGradient(colors: [AuraColors.blueSoft.opacity(0.6), AuraColors.orangeSoft.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: AuraCorners.large))

                HStack {
                    Text("TUS 3 ACCIONES DIARIAS")
                        .font(AuraTypography.caption)
                        .foregroundStyle(AuraColors.textSecondary)
                    Spacer()
                    Button("Completar todo →") {
                        viewModel.completeAllActions()
                    }
                        .font(AuraTypography.footnote)
                        .foregroundStyle(AuraColors.primary)
                }

                ForEach(Array(viewModel.actions.enumerated()), id: \.element.id) { index, action in
                    actionCard(action: action, index: index, isCompleted: viewModel.isActionCompleted(action.id))
                }
            }
            .padding(AuraSpacing.large)
        }
        .background(AuraColors.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.refreshData()
        }
        .refreshable {
            await viewModel.refreshData()
        }
    }

    private var stepsText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: viewModel.stepsToday)) ?? "\(viewModel.stepsToday)"
    }

    private var sleepText: String {
        String(format: "%.1f", viewModel.sleepHours)
    }

    private var caloriesText: String {
        "\(viewModel.activeCalories)"
    }

    private func statPill(text: String, background: Color, foreground: Color) -> some View {
        Text(text)
            .font(AuraTypography.footnote)
            .foregroundStyle(foreground)
            .padding(.horizontal, AuraSpacing.medium)
            .padding(.vertical, AuraSpacing.small)
            .background(background)
            .clipShape(Capsule())
    }

    private func metricCard(value: String, unit: String, background: Color, foreground: Color) -> some View {
        VStack(alignment: .leading, spacing: AuraSpacing.small) {
            Text(value)
                .font(AuraTypography.title2)
                .foregroundStyle(foreground)
            Text(unit)
                .font(AuraTypography.mini)
                .foregroundStyle(foreground.opacity(0.85))
        }
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .bottomLeading)
        .padding(AuraSpacing.medium)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: AuraCorners.large))
    }

    private func actionCard(action: MicroAction, index: Int, isCompleted: Bool) -> some View {
        HStack(spacing: AuraSpacing.medium) {
            ZStack {
                Circle()
                    .fill(AuraColors.surfaceMuted)
                    .frame(width: 38, height: 38)
                Text(index == 0 ? "💧" : (index == 1 ? "🧘" : "👟"))
            }

            VStack(alignment: .leading, spacing: AuraSpacing.xSmall) {
                Text(action.title)
                    .font(AuraTypography.bodyStrong)
                    .foregroundStyle(AuraColors.textPrimary)
                Text(action.description)
                    .font(AuraTypography.footnote)
                    .foregroundStyle(index == 2 ? AuraColors.secondary : AuraColors.textSecondary)
            }

            Spacer()

            Button {
                viewModel.toggleActionCompletion(action.id)
            } label: {
                ZStack {
                    Circle()
                        .fill(isCompleted ? AuraColors.primary : .clear)
                        .overlay(
                            Circle()
                                .stroke(isCompleted ? AuraColors.primary : AuraColors.cardStroke, lineWidth: 2)
                        )
                        .frame(width: 28, height: 28)

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(AuraSpacing.medium)
        .background(AuraColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AuraCorners.medium))
        .overlay(
            RoundedRectangle(cornerRadius: AuraCorners.medium)
                .stroke(AuraColors.cardStroke.opacity(0.7), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
