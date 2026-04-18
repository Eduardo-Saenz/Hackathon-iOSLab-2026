import SwiftUI

@MainActor
struct CoachView: View {
    @StateObject private var viewModel: CoachViewModel
    private let entryMessage: String?

    @State private var didApplyEntryMessage = false
    @State private var sendButtonScale: CGFloat = 1.0
    @FocusState private var isTextFieldFocused: Bool

    init() {
        self.entryMessage = nil
        _viewModel = StateObject(wrappedValue: CoachViewModel())
    }

    init(entryMessage: String?) {
        self.entryMessage = entryMessage
        _viewModel = StateObject(wrappedValue: CoachViewModel())
    }

    init(viewModel: CoachViewModel, entryMessage: String? = nil) {
        self.entryMessage = entryMessage
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private var shouldShowEntryBanner: Bool {
        guard let entryMessage else { return false }
        return !entryMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: AuraSpacing.medium) {
                    if shouldShowEntryBanner {
                        entryBanner
                            .padding(.top, AuraSpacing.small)
                    }

                    if viewModel.messages.isEmpty {
                        emptyState
                    } else {
                        ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                            messageRow(message)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                    }

                    if viewModel.isLoading {
                        HStack(spacing: AuraSpacing.small) {
                            TypingDotsView()
                            Text("Buddy escribiendo...")
                                .font(AuraTypography.footnote)
                                .foregroundStyle(AuraColors.textSecondary)
                        }
                        .padding(.top, AuraSpacing.small)
                        .transition(.opacity)
                    }

                    if let errorMessage = viewModel.errorMessage {
                        errorBanner(errorMessage)
                    }

                       
                }
                .padding(.vertical, AuraSpacing.medium)
            }
            .background(
                ZStack {
                    AuraColors.surface
                    FloatingOrbsView()
                        .opacity(0.3)
                }
            )
            .onTapGesture {
                isTextFieldFocused = false
            }

            VStack(spacing: AuraSpacing.medium) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AuraSpacing.small) {
                        ForEach(viewModel.quickReplies, id: \.self) { reply in
                            Button {
                                viewModel.draftMessage = reply
                                isTextFieldFocused = true
                            } label: {
                                Text(reply)
                                    .font(AuraTypography.footnote)
                                    .foregroundStyle(AuraColors.textSecondary)
                                    .padding(.horizontal, AuraSpacing.medium)
                                    .padding(.vertical, AuraSpacing.small)
                                    .background(AuraColors.surfaceMuted)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(AuraColors.cardStroke, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AuraSpacing.medium)
                }
                .padding(.top, AuraSpacing.small)

                HStack(spacing: AuraSpacing.small) {
                    TextField("Escribe un mensaje...", text: $viewModel.draftMessage, axis: .vertical)
                        .font(AuraTypography.body)
                        .foregroundStyle(AuraColors.primary)
                        .tint(AuraColors.primary)
                        .padding(.horizontal, AuraSpacing.medium)
                        .padding(.vertical, 12)
                        .background(AuraColors.surfaceMuted)
                        .clipShape(RoundedRectangle(cornerRadius: AuraCorners.medium))
                        .lineLimit(1...4)
                        .focused($isTextFieldFocused)

                    Button {
                        withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
                            sendButtonScale = 0.88
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                sendButtonScale = 1.0
                            }
                        }
                        viewModel.sendDraft()
                        isTextFieldFocused = false
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(
                                canSendDraft
                                ? AuraColors.primary
                                : AuraColors.textSecondary.opacity(0.35)
                            )
                            .clipShape(Circle())
                            .scaleEffect(sendButtonScale)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSendDraft || viewModel.isLoading)
                }
                .padding(.horizontal, AuraSpacing.medium)
                .padding(.bottom, AuraSpacing.medium)
            }
            .background(AuraColors.surface)
            .shadow(color: Color.black.opacity(0.04), radius: 8, y: -4)
        }
        .background(AuraColors.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(false)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            applyEntryMessageIfNeeded()
        }
    }

    private var canSendDraft: Bool {
        !viewModel.draftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var emptyState: some View {
        VStack(spacing: AuraSpacing.small) {
            Image(systemName: "bubble.left.and.text.bubble.right")
                .font(.system(size: 28))
                .foregroundStyle(AuraColors.textSecondary)
            Text("Empieza una conversación con tu buddy")
                .font(AuraTypography.bodyStrong)
                .foregroundStyle(AuraColors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AuraSpacing.large)
    }

    private var header: some View {
        HStack(spacing: AuraSpacing.smedium) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [AuraColors.primary, AuraColors.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 48, height: 48)
                .overlay(Text(""))

            VStack(alignment: .leading, spacing: AuraSpacing.xSmall) {
                Text("Tu Buddy")
                    .font(AuraTypography.headline)
                    .foregroundStyle(AuraColors.textPrimary)

                Text("● En línea · Aura AI")
                    .font(AuraTypography.footnote)
                    .foregroundStyle(AuraColors.primary)
            }

            Spacer()
        }
        .padding(.horizontal, AuraSpacing.medium)
        .padding(.vertical, AuraSpacing.smedium)
        .background(AuraColors.surface)
    }

    private var entryBanner: some View {
        VStack(alignment: .leading, spacing: AuraSpacing.small) {
            HStack(spacing: 8) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AuraColors.primary)

                Text("Entrada desde tu diario")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(AuraColors.primary)
                    .tracking(0.4)
            }

            Text("Esto es para mi diario. Puedes escribir o hablar aquí con tu coach sobre cómo te fue hoy.")
                .font(AuraTypography.body)
                .foregroundStyle(AuraColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if let entryMessage, !entryMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                HStack(spacing: 8) {
                    Circle()
                        .fill(AuraColors.primary.opacity(0.9))
                        .frame(width: 8, height: 8)

                    Text(entryMessage)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(AuraColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AuraSpacing.medium)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AuraCorners.large))
        .overlay(
            RoundedRectangle(cornerRadius: AuraCorners.large)
                .stroke(AuraColors.cardStroke.opacity(0.32), lineWidth: 1)
        )
        .padding(.horizontal, AuraSpacing.medium)
    }

    private func messageRow(_ message: CoachMessage) -> some View {
        VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: AuraSpacing.xSmall) {
            HStack {
                if message.isFromUser { Spacer() }

                Text(message.text)
                    .font(AuraTypography.bodyStrong)
                    .foregroundStyle(message.isFromUser ? .white : AuraColors.textPrimary)
                    .padding(AuraSpacing.medium)
                    .background(message.isFromUser ? AuraColors.primary : AuraColors.surfaceMuted)
                    .clipShape(RoundedRectangle(cornerRadius: AuraCorners.large))

                if !message.isFromUser { Spacer() }
            }

            Text(message.time)
                .font(AuraTypography.caption)
                .foregroundStyle(AuraColors.textSecondary)
        }
        .padding(.horizontal, AuraSpacing.medium)
    }

    private func errorBanner(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: AuraSpacing.small) {
            Text("No se pudo enviar el mensaje")
                .font(AuraTypography.footnote)
                .foregroundStyle(.red)
            Text(message)
                .font(AuraTypography.mini)
                .foregroundStyle(AuraColors.textSecondary)
            Button("Reintentar") {
                viewModel.retryLastMessage()
            }
            .font(AuraTypography.footnote)
            .foregroundStyle(AuraColors.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AuraSpacing.medium)
        .background(AuraColors.surfaceMuted)
        .clipShape(RoundedRectangle(cornerRadius: AuraCorners.medium))
        .padding(.horizontal, AuraSpacing.medium)
    }

    private func applyEntryMessageIfNeeded() {
        guard !didApplyEntryMessage else { return }
        didApplyEntryMessage = true

        guard let entryMessage else { return }
        let trimmed = entryMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if viewModel.draftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            viewModel.draftMessage = trimmed
        }
    }
}

#Preview {
    NavigationStack {
        CoachView(viewModel: PreviewMocks.coachViewModel(), entryMessage: "Esto es para mi diario")
    }
}
