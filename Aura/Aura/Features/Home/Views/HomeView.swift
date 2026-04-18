import SwiftUI
import Foundation

@MainActor
struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @State private var selectedEmotion: String? = nil

    init() {
        _viewModel = StateObject(wrappedValue: HomeViewModel())
    }

    init(viewModel: HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    let emotions = ["Ira", "Asco", "Felicidad", "Tristeza", "Sorpresa", "Miedo", "Estrés"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AuraSpacing.large) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(viewModel.greeting) 💙")
                        .font(AuraTypography.title2)
                        .foregroundStyle(AuraColors.textPrimary)
                    Text("Estamos aquí contigo, un día a la vez.")
                        .font(AuraTypography.footnote)
                        .foregroundStyle(AuraColors.textSecondary)
                }

                // Mood Picker
                VStack(spacing: AuraSpacing.large) {
                    HStack {
                        Image(systemName: "heart")
                            .foregroundStyle(.red)
                        Text("¿Cómo te sientes ahora mismo?")
                            .font(AuraTypography.bodyStrong)
                            .foregroundStyle(AuraColors.textPrimary)
                        Spacer()
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AuraSpacing.medium) {
                            ForEach(emotions, id: \.self) { emotion in
                                let isSelected = selectedEmotion == emotion
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedEmotion = emotion
                                    }
                                } label: {
                                    VStack(spacing: 8) {
                                        Circle()
                                            .fill(isSelected ? colorForEmotion(emotion) : colorForEmotion(emotion).opacity(0.15))
                                            .frame(width: 48, height: 48)
                                            .overlay(
                                                Text(String(emotion.prefix(1)).uppercased())
                                                    .font(.headline)
                                                    .bold()
                                                    .foregroundStyle(isSelected ? .white : colorForEmotion(emotion))
                                            )
                                        Text(emotion)
                                            .font(AuraTypography.mini)
                                            .foregroundStyle(isSelected ? AuraColors.textPrimary : AuraColors.textSecondary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Button {
                        if selectedEmotion != nil {
                            withAnimation {
                                selectedEmotion = nil
                            }
                        }
                    } label: {
                        Text("Registrar estado de ánimo")
                            .font(AuraTypography.footnote)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(selectedEmotion != nil ? AuraColors.primary : Color.gray.opacity(0.15))
                            .foregroundStyle(selectedEmotion != nil ? .white : AuraColors.textSecondary)
                            .clipShape(Capsule())
                    }
                    .disabled(selectedEmotion == nil)
                }
                .padding(AuraSpacing.large)
                .background(AuraColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AuraCorners.large))
                .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)

                // Consejero AI
                VStack(alignment: .leading, spacing: AuraSpacing.medium) {
                    HStack(spacing: AuraSpacing.small) {
                        ZStack {
                            Circle().fill(AuraColors.surface).frame(width: 36, height: 36)
                            Image(systemName: "stethoscope")
                                .foregroundStyle(AuraColors.primary)
                                .font(.system(size: 14))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TU CONSEJERO AI")
                                .font(AuraTypography.mini)
                                .foregroundStyle(AuraColors.primary)
                                .tracking(1)
                            Text("Basado en tus últimos registros de Apple Health")
                                .font(AuraTypography.mini)
                                .foregroundStyle(AuraColors.textSecondary)
                        }
                    }

                    if let focusArea = viewModel.focusArea, !focusArea.isEmpty {
                        Text("FOCO: \(focusArea)")
                            .font(AuraTypography.mini)
                            .foregroundStyle(AuraColors.primary)
                            .padding(.horizontal, AuraSpacing.small)
                            .padding(.vertical, AuraSpacing.xSmall)
                            .background(AuraColors.surface.opacity(0.9))
                            .clipShape(Capsule())
                    }

                    Text("\"\(viewModel.summary)\"")
                        .font(AuraTypography.bodyStrong)
                        .foregroundStyle(AuraColors.textPrimary)

                    if viewModel.diagnosticsVisible {
                        Text(viewModel.backendSyncStatusText)
                            .font(AuraTypography.mini)
                            .foregroundStyle(AuraColors.textSecondary)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("DEV DIAGNÓSTICO")
                                .font(AuraTypography.mini)
                                .foregroundStyle(AuraColors.primary)
                            Text("Servicio: \(viewModel.backendModeText)")
                                .font(AuraTypography.mini)
                                .foregroundStyle(AuraColors.textSecondary)
                            Text("Último refresh: \(viewModel.lastRefreshText)")
                                .font(AuraTypography.mini)
                                .foregroundStyle(AuraColors.textSecondary)
                            Text("Primer action id: \(viewModel.diagnosticFirstActionID)")
                                .font(AuraTypography.mini)
                                .foregroundStyle(AuraColors.textSecondary)
                        }
                        .padding(.horizontal, AuraSpacing.small)
                        .padding(.vertical, AuraSpacing.xSmall)
                        .background(AuraColors.surface.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: AuraCorners.small))
                    }

                    HStack(spacing: AuraSpacing.small) {
                        statPillAI(icon: "moon.zzz.fill", text: "\(String(format: "%.1f", viewModel.sleepHours))h sueño")
                        statPillAI(icon: "figure.walk", text: "\(viewModel.stepsToday) pasos")
                    }
                }
                .padding(AuraSpacing.large)
                .background(
                    ZStack {
                        LinearGradient(
                            colors: [AuraColors.blueSoft.opacity(0.5), AuraColors.orangeSoft.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                        // Resplandor difuminado tipo inicio de sesión
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AuraColors.accentMint.opacity(0.8), AuraColors.accentLavender.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 200, height: 200)
                            .blur(radius: 40)
                            .offset(x: 100, y: -40)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: AuraCorners.large))
                )
                // Remove the extra clipShape from here, as we already clip the ZStack above
                .shadow(color: AuraColors.primary.opacity(0.05), radius: 10, y: 5)

                // Accion Principal
                if let primaryAction = viewModel.actions.first {
                    VStack(alignment: .leading, spacing: AuraSpacing.medium) {
                        HStack {
                            Text("ACCIÓN PRINCIPAL")
                                .font(AuraTypography.mini)
                                .foregroundStyle(AuraColors.primary)
                                .tracking(1)
                            Spacer()
                        }
                        .padding(.horizontal, AuraSpacing.large)
                        .padding(.top, AuraSpacing.large)

                        HStack(alignment: .top, spacing: AuraSpacing.medium) {
                            ZStack {
                                Circle().fill(AuraColors.surface).frame(width: 48, height: 48)
                                Image(systemName: iconForCategory(primaryAction.category))
                                    .foregroundStyle(AuraColors.primary)
                                    .font(.system(size: 20))
                            }
                            
                            VStack(alignment: .leading, spacing: AuraSpacing.xSmall) {
                                Text("\(primaryAction.title) (\(primaryAction.estimatedMinutes) min)")
                                    .font(AuraTypography.bodyStrong)
                                    .foregroundStyle(AuraColors.textPrimary)
                                
                                Text(primaryAction.justification ?? primaryAction.description)
                                    .font(AuraTypography.footnote)
                                    .foregroundStyle(AuraColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.horizontal, AuraSpacing.large)

                        Button {
                            viewModel.toggleActionCompletion(primaryAction.id)
                        } label: {
                            Text(viewModel.isActionCompleted(primaryAction.id) ? "Completado" : "Comenzar ahora")
                                .font(AuraTypography.footnote)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(viewModel.isActionCompleted(primaryAction.id) ? AuraColors.primary.opacity(0.5) : Color(hex: "#0F172A"))
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, AuraSpacing.large)
                        .padding(.bottom, AuraSpacing.large)
                        .disabled(viewModel.isActionCompleted(primaryAction.id))
                    }
                    .background(Color(hex: "#E8F4F8")) // Soft cyan blue background
                    .clipShape(RoundedRectangle(cornerRadius: AuraCorners.large))
                    .overlay(
                        RoundedRectangle(cornerRadius: AuraCorners.large)
                            .stroke(AuraColors.cardStroke.opacity(0.5), lineWidth: 1)
                    )
                }

                // Complementa
                if viewModel.actions.count > 1 {
                    VStack(alignment: .leading, spacing: AuraSpacing.medium) {
                        Text("COMPLEMENTA TU BIENESTAR")
                            .font(AuraTypography.mini)
                            .foregroundStyle(AuraColors.textSecondary)
                            .tracking(1)

                        ForEach(Array(viewModel.actions.dropFirst().enumerated()), id: \.element.id) { index, action in
                            actionCard(action: action, index: index + 1, isCompleted: viewModel.isActionCompleted(action.id))
                        }
                    }
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

    private func colorForEmotion(_ emotion: String) -> Color {
        switch emotion {
        case "Ira": return .red
        case "Asco": return .green
        case "Felicidad": return .yellow
        case "Tristeza": return .blue
        case "Sorpresa": return .orange
        case "Miedo": return .purple
        case "Estrés": return .pink
        default: return .gray
        }
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "hidratacion": return "drop.fill"
        case "movilidad": return "figure.mind.and.body"
        case "actividad": return "figure.walk"
        default: return "sparkles"
        }
    }

    private func statPillAI(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(AuraColors.primary)
            Text(text)
                .font(AuraTypography.mini)
                .foregroundStyle(AuraColors.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AuraColors.surface.opacity(0.9))
        .clipShape(Capsule())
    }

    private func actionCard(action: MicroAction, index: Int, isCompleted: Bool) -> some View {
        HStack(spacing: AuraSpacing.medium) {
            ZStack {
                Circle()
                    .fill(AuraColors.surfaceMuted)
                    .frame(width: 40, height: 40)
                Image(systemName: iconForCategory(action.category))
                    .foregroundStyle(AuraColors.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(action.title)
                    .font(AuraTypography.bodyStrong)
                    .foregroundStyle(AuraColors.textPrimary)
                Text(action.description)
                    .font(AuraTypography.footnote)
                    .foregroundStyle(AuraColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
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
        .padding(AuraSpacing.large)
        .background(AuraColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AuraCorners.large))
        .overlay(
            RoundedRectangle(cornerRadius: AuraCorners.large)
                .stroke(AuraColors.cardStroke.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
