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
        ZStack {
            AuraColors.background.ignoresSafeArea()
            
            // Soft moonlit glow
            Circle()
                .fill(
                    LinearGradient(
                        colors: [AuraColors.accentMint.opacity(0.8), AuraColors.accentLavender.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 280, height: 280)
                .blur(radius: 60)
                .offset(y: -200)

            ScrollView {
                VStack(alignment: .leading, spacing: AuraSpacing.xLarge) {
                    Text("Aura")
                        .font(AuraTypography.hero)
                        .foregroundStyle(AuraColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 80)
                        // Add slight shadow to stand out against glow
                        .shadow(color: AuraColors.surface.opacity(0.5), radius: 2)

                    VStack(alignment: .leading, spacing: AuraSpacing.medium) {
                        credentialField(title: "Email", placeholder: "tu@email.com", text: $email)
                        secureCredentialField(title: "Contraseña", placeholder: "••••", text: $password)

                        Button("¿Olvidaste tu contraseña?") {}
                            .font(AuraTypography.footnote)
                            .foregroundStyle(AuraColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal, AuraSpacing.small)

                    VStack(spacing: AuraSpacing.medium) {
                        Button {
                            onContinue()
                        } label: {
                            Text("Iniciar Sesión")
                                .font(AuraTypography.bodyStrong)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AuraSpacing.medium)
                                .background(AuraColors.primary)
                                .clipShape(RoundedRectangle(cornerRadius: AuraCorners.medium))
                                .shadow(color: AuraColors.primary.opacity(0.3), radius: 8, y: 4)
                        }

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
                                .background(Color.black)
                                .clipShape(RoundedRectangle(cornerRadius: AuraCorners.medium))
                                .shadow(color: Color.black.opacity(0.2), radius: 8, y: 4)
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
                                .shadow(color: AuraColors.shadowCool, radius: 10, y: 4)
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
        }
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
                .shadow(color: AuraColors.shadowCool.opacity(0.6), radius: 8, y: 3)
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
                .shadow(color: AuraColors.shadowCool.opacity(0.6), radius: 8, y: 3)
        }
    }
}

#Preview {
    LoginView()
}

