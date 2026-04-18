import SwiftUI
import Foundation

@MainActor
struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @State private var selectedEmotion: String? = nil
    @State private var cardAppeared = false
    @State private var lastCompletedId: String? = nil
    @State private var showRipple = false
    @State private var selectionGlowActive = false
    @State private var scrollOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init() {
        _viewModel = StateObject(wrappedValue: HomeViewModel())
    }

    init(viewModel: HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    let emotions = ["Ira", "Asco", "Felicidad", "Tristeza", "Sorpresa", "Miedo", "Estrés"]

    var body: some View {
        ZStack {
            AuraColors.background.ignoresSafeArea()

            // Floating orbs background
            FloatingOrbsView()
                .opacity(0.6)
                .ignoresSafeArea()
                .offset(y: scrollOffset * -0.4) // Parallax depth

            ScrollView {
                // Tracking scroll offset for parallax
                GeometryReader { geo in
                    Color.clear.preference(key: ScrollOffsetKey.self, value: geo.frame(in: .named("homeScroll")).minY)
                }
                .frame(height: 0)

                VStack(alignment: .leading, spacing: AuraSpacing.large) {
                    // Header with streak
                    headerSection

                    // Mood Picker
                    moodPickerSection

                    // Compassionate Response
                    if let response = viewModel.compassionateResponse {
                        Text(response)
                            .font(AuraTypography.footnote)
                            .foregroundStyle(AuraColors.textSecondary)
                            .padding(AuraSpacing.medium)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AuraColors.accentMint.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: AuraCorners.medium))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Consejero AI
                    coachSection
                        .opacity(cardAppeared ? 1 : 0)
                        .offset(y: cardAppeared ? 0 : 20)

                    // Loading
                    if viewModel.loadState == .loading {
                        VStack(spacing: AuraSpacing.medium) {
                            ShimmerPlaceholder(height: 100)
                            ShimmerPlaceholder(height: 80)
                            ShimmerPlaceholder(height: 80)
                        }
                    } else {
                        // Primary Action
                        if let primaryAction = viewModel.actions.first {
                            primaryActionCard(primaryAction)
                                .opacity(cardAppeared ? 1 : 0)
                                .offset(y: cardAppeared ? 0 : 30)
                                .animation(reduceMotion ? .default : AuraAnimations.staggered(index: 1), value: cardAppeared)
                        }

                        // Complementary Actions
                        if viewModel.actions.count > 1 {
                            VStack(alignment: .leading, spacing: AuraSpacing.medium) {
                                Text("COMPLEMENTA TU BIENESTAR")
                                    .font(AuraTypography.mini)
                                    .foregroundStyle(AuraColors.textSecondary)
                                    .tracking(1)

                                ForEach(Array(viewModel.actions.dropFirst().enumerated()), id: \.element.id) { index, action in
                                    actionCard(action: action, index: index + 1, isCompleted: viewModel.isActionCompleted(action.id))
                                        .opacity(cardAppeared ? 1 : 0)
                                        .offset(y: cardAppeared ? 0 : 20)
                                        .animation(reduceMotion ? .default : AuraAnimations.staggered(index: index + 2), value: cardAppeared)
                                }
                            }
                        }
                    }
                }
                .padding(AuraSpacing.large)
            }

            // Streak Celebration overlay
            StreakCelebrationView(isActive: $viewModel.showStreakCelebration)
                .allowsHitTesting(false)
        }
        .coordinateSpace(name: "homeScroll")
        .onPreferenceChange(ScrollOffsetKey.self) { value in
            scrollOffset = value
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.refreshData()
            withAnimation(reduceMotion ? .default : AuraAnimations.entrance) {
                cardAppeared = true
            }
            selectionGlowActive = true
        }
        .refreshable {
            await viewModel.refreshData()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(viewModel.greeting)")
                    .font(AuraTypography.title2)
                    .foregroundStyle(AuraColors.textPrimary)
                Text("Estamos aquí contigo, un día a la vez.")
                    .font(AuraTypography.footnote)
                    .foregroundStyle(AuraColors.textSecondary)
            }
            Spacer()
            if viewModel.streakDays > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                        .font(.system(size: 16))
                    Text("\(viewModel.streakDays)")
                        .font(AuraTypography.bodyStrong)
                        .foregroundStyle(AuraColors.textPrimary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AuraColors.surface)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
            }
        }
    }

    // MARK: - Mood Picker

    private var moodPickerSection: some View {
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
                                ZStack {
                                    // Liquid glow behind selected
                                    if isSelected {
                                        Circle()
                                            .fill(colorForEmotion(emotion).opacity(0.3))
                                            .frame(width: 64, height: 64)
                                            .blur(radius: 12)
                                            .scaleEffect(selectionGlowActive ? 1.2 : 1.0)
                                            .animation(AuraAnimations.breathe, value: selectionGlowActive)
                                    }
                                    Circle()
                                        .fill(isSelected ? colorForEmotion(emotion) : colorForEmotion(emotion).opacity(0.15))
                                        .frame(width: 48, height: 48)
                                        .scaleEffect(isSelected ? 1.15 : 1.0)
                                        .shadow(color: isSelected ? colorForEmotion(emotion).opacity(0.4) : .clear, radius: 10, y: 5)
                                        .overlay(
                                            Text(String(emotion.prefix(1)).uppercased())
                                                .font(.headline)
                                                .bold()
                                                .foregroundStyle(isSelected ? .white : colorForEmotion(emotion))
                                        )
                                }
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
                if let emotion = selectedEmotion {
                    Task {
                        await viewModel.submitEmotion(label: emotion)
                    }
                    withAnimation(AuraAnimations.calm) {
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
            .scaleEffect(selectedEmotion != nil ? (selectionGlowActive ? 1.02 : 1.0) : 1.0)
            .animation(selectedEmotion != nil ? AuraAnimations.breathe : .default, value: selectionGlowActive)
            .disabled(selectedEmotion == nil)
        }
        .padding(AuraSpacing.large)
        .background(AuraColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AuraCorners.large))
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
    }

    // MARK: - AI Coach Section

    private var coachSection: some View {
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

            if let why = viewModel.whyThisToday, !why.isEmpty {
                Text(why)
                    .font(AuraTypography.footnote)
                    .foregroundStyle(AuraColors.textSecondary)
                    .italic()
            }

            if viewModel.diagnosticsVisible {
                diagnosticsSection
            }

            HStack(spacing: AuraSpacing.small) {
                statPillAI(icon: "moon.zzz.fill", text: "\(String(format: "%.1f", viewModel.sleepHours))h sueño")
                statPillAI(icon: "figure.walk", text: "\(viewModel.stepsToday) pasos")
            }
        }
        .padding(AuraSpacing.large)
        .background(
            ZStack {
                // Morphing gradient background
                GradientMorphView()

                LinearGradient(
                    colors: [AuraColors.blueSoft.opacity(0.5), AuraColors.orangeSoft.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Breathing circle behind
                BreathingCircleView()
                    .frame(width: 200, height: 200)
                    .offset(x: 80, y: -30)
            }
            .clipShape(RoundedRectangle(cornerRadius: AuraCorners.large))
        )
        .shadow(color: AuraColors.primary.opacity(0.05), radius: 10, y: 5)
    }

    private var diagnosticsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.backendSyncStatusText)
                .font(AuraTypography.mini)
                .foregroundStyle(AuraColors.textSecondary)
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

    // MARK: - Primary Action

    private func primaryActionCard(_ action: MicroAction) -> some View {
        let completed = viewModel.isActionCompleted(action.id)
        return VStack(alignment: .leading, spacing: AuraSpacing.medium) {
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
                    Image(systemName: iconForCategory(action.category))
                        .foregroundStyle(AuraColors.primary)
                        .font(.system(size: 20))
                }

                VStack(alignment: .leading, spacing: AuraSpacing.xSmall) {
                    Text("\(action.title) (\(action.estimatedMinutes) min)")
                        .font(AuraTypography.bodyStrong)
                        .foregroundStyle(AuraColors.textPrimary)
                    Text(action.justification ?? action.description)
                        .font(AuraTypography.footnote)
                        .foregroundStyle(AuraColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, AuraSpacing.large)

            Button {
                withAnimation(AuraAnimations.calm) {
                    viewModel.toggleActionCompletion(action.id)
                    showRipple = true
                    lastCompletedId = action.id
                }
            } label: {
                Text(completed ? "Completado" : "Comenzar ahora")
                    .font(AuraTypography.footnote)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(completed ? AuraColors.primary.opacity(0.5) : Color(hex: "#0F172A"))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .scaleEffect(!completed && selectionGlowActive ? 1.02 : 1.0)
                    .animation(!completed ? AuraAnimations.breathe : .default, value: selectionGlowActive)
            }
            .rippleOnTap(trigger: lastCompletedId == action.id && showRipple)
            .padding(.horizontal, AuraSpacing.large)
            .padding(.bottom, AuraSpacing.large)
            .disabled(completed)
        }
        .background(Color(hex: "#E8F4F8"))
        .clipShape(RoundedRectangle(cornerRadius: AuraCorners.large))
        .overlay(
            RoundedRectangle(cornerRadius: AuraCorners.large)
                .stroke(AuraColors.cardStroke.opacity(0.5), lineWidth: 1)
        )
    }

    // MARK: - Action Card

    private func actionCard(action: MicroAction, index: Int, isCompleted: Bool) -> some View {
        SwipeableActionView(isCompleted: isCompleted) {
            viewModel.toggleActionCompletion(action.id)
        } content: {
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
                
                if isCompleted {
                    ZStack {
                        Circle()
                            .fill(AuraColors.primary)
                            .frame(width: 28, height: 28)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                } else {
                    // Swipe indicator
                    HStack(spacing: 2) {
                        Image(systemName: "chevron.right")
                        Image(systemName: "chevron.right")
                            .opacity(0.5)
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AuraColors.cardStroke)
                    .padding(.trailing, 8)
                }
            }
            .padding(AuraSpacing.large)
        }
    }

    // MARK: - Helpers

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
        case "actividad", "steps": return "figure.walk"
        case "sleep": return "moon.zzz.fill"
        case "energy": return "bolt.heart.fill"
        case "mindfulness", "mindset": return "brain.head.profile"
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
}

// MARK: - Handlers
struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}

#Preview {
    NavigationStack {
        HomeView(viewModel: PreviewMocks.homeViewModel())
    }
}
