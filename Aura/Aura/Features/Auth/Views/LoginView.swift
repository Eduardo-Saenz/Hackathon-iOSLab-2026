import SwiftUI

@MainActor
struct LoginView: View {
    @StateObject private var viewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    let onContinue: () -> Void

    init(onContinue: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(appPreferences: .shared))
        self.onContinue = onContinue
    }

    init(viewModel: AuthViewModel, onContinue: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onContinue = onContinue
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AuraSpacing.xLarge) {
                Text("AURA")
                    .font(AuraTypography.hero)
                    .foregroundStyle(AuraColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 56)

                VStack(alignment: .leading, spacing: AuraSpacing.medium) {
                    credentialField(title: "EMAIL", placeholder: "tu@email.com", text: $email)
                    secureCredentialField(title: "CONTRASEÑA", placeholder: "••••", text: $password)

                    Button("¿Olvidaste tu contraseña?") {}
                        .font(AuraTypography.footnote)
                        .foregroundStyle(AuraColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, AuraSpacing.small)

                VStack(spacing: AuraSpacing.medium) {
                    Button {
                        Task {
                            await viewModel.signInWithApple()
                            onContinue()
                        }
                    } label: {
                        Text("Continuar con Apple")
                            .font(AuraTypography.bodyStrong)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AuraSpacing.medium)
                            .background(AuraColors.primaryDark)
                            .clipShape(RoundedRectangle(cornerRadius: AuraCorners.medium))
                    }

                    Button {
                        Task {
                            await viewModel.signInWithGoogle()
                            onContinue()
                        }
                    } label: {
                        Text("Continuar con Google")
                            .font(AuraTypography.bodyStrong)
                            .foregroundStyle(AuraColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AuraSpacing.medium)
                            .background(AuraColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AuraCorners.medium))
                            .overlay(
                                RoundedRectangle(cornerRadius: AuraCorners.medium)
                                    .stroke(AuraColors.cardStroke, lineWidth: 1)
                            )
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(AuraTypography.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, AuraSpacing.xLarge)
            .padding(.bottom, AuraSpacing.xLarge)
        }
        .background(AuraColors.background.ignoresSafeArea())
    }

    private func credentialField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: AuraSpacing.small) {
            Text(title)
                .font(AuraTypography.footnote)
                .foregroundStyle(AuraColors.textSecondary)

            TextField(placeholder, text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(AuraTypography.body)
                .padding(.horizontal, AuraSpacing.medium)
                .padding(.vertical, AuraSpacing.smedium)
                .background(AuraColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AuraCorners.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: AuraCorners.medium)
                        .stroke(AuraColors.cardStroke, lineWidth: 1)
                )
        }
    }

    private func secureCredentialField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: AuraSpacing.small) {
            Text(title)
                .font(AuraTypography.footnote)
                .foregroundStyle(AuraColors.textSecondary)

            SecureField(placeholder, text: text)
                .font(AuraTypography.body)
                .padding(.horizontal, AuraSpacing.medium)
                .padding(.vertical, AuraSpacing.smedium)
                .background(AuraColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AuraCorners.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: AuraCorners.medium)
                        .stroke(AuraColors.cardStroke, lineWidth: 1)
                )
        }
    }
}

#Preview {
    LoginView()
}
