import SwiftUI

@MainActor
struct CoachView: View {
    @StateObject private var viewModel: CoachViewModel

    init() {
        _viewModel = StateObject(wrappedValue: CoachViewModel())
    }

    init(viewModel: CoachViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: AuraSpacing.medium) {
                    ForEach(viewModel.messages) { message in
                        messageRow(message)
                    }
                }
                .padding(.vertical, AuraSpacing.medium)
            }
            .background(AuraColors.surface)

            // Input Area + Quick Replies anchored at the bottom
            VStack(spacing: AuraSpacing.medium) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AuraSpacing.small) {
                        ForEach(viewModel.quickReplies, id: \.self) { reply in
                            Button {
                                viewModel.draftMessage = reply
                            } label: {
                                Text(reply)
                                    .font(AuraTypography.footnote)
                                    .foregroundStyle(AuraColors.textSecondary)
                                    .padding(.horizontal, AuraSpacing.medium)
                                    .padding(.vertical, AuraSpacing.small)
                                    .background(AuraColors.surfaceMuted)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(AuraColors.cardStroke, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, AuraSpacing.medium)
                }
                .padding(.top, AuraSpacing.small)

                HStack(spacing: AuraSpacing.small) {
                    TextField("Escribe un mensaje...", text: $viewModel.draftMessage)
                        .font(AuraTypography.body)
                        .padding(.horizontal, AuraSpacing.medium)
                        .padding(.vertical, 12)
                        .background(AuraColors.surfaceMuted)
                        .clipShape(RoundedRectangle(cornerRadius: AuraCorners.medium))

                    Button {
                        viewModel.sendDraft()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(AuraColors.primary)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, AuraSpacing.medium)
                .padding(.bottom, AuraSpacing.medium)
            }
            .background(AuraColors.surface)
            .shadow(color: Color.black.opacity(0.04), radius: 8, y: -4)
        }
        .background(AuraColors.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
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
                .overlay(Text("🤖"))

            VStack(alignment: .leading, spacing: AuraSpacing.xSmall) {
                Text("Tu Coach AI")
                    .font(AuraTypography.headline)
                    .foregroundStyle(AuraColors.textPrimary)
                Text("● En línea · Bienestar AI")
                    .font(AuraTypography.footnote)
                    .foregroundStyle(AuraColors.primary)
            }
            Spacer()
        }
        .padding(.horizontal, AuraSpacing.medium)
        .padding(.vertical, AuraSpacing.smedium)
        .background(AuraColors.surface)
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
}

#Preview {
    NavigationStack {
        CoachView()
    }
}
