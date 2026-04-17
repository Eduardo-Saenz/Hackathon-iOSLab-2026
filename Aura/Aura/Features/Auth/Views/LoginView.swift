import SwiftUI
import AuthenticationServices

@MainActor
struct LoginView: View {
    @StateObject private var viewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""

    init(onContinue: @escaping () -> Void = {}) {
        let vm = AuthViewModel(appPreferences: .shared)
        vm.onAuthSuccess = onContinue
        _viewModel = StateObject(wrappedValue: vm)
    }

    init(viewModel: AuthViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
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
                        .shadow(color: AuraColors.surface.opacity(0.5), radius: 2)

                    // Toggle sign-in / sign-up
                    Picker("", selection: $viewModel.isSignUpMode) {
                        Text("Iniciar Sesión").tag(false)
                        Text("Crear Cuenta").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, AuraSpacing.small)

                    VStack(alignment: .leading, spacing: AuraSpacing.medium) {
                        credentialField(title: "Email", placeholder: "tu@email.com", text: $email)
                            .keyboardType(.emailAddress)
                        secureCredentialField(title: "Contraseña", placeholder: "••••••", text: $password)
                    }
                    .padding(.horizontal, AuraSpacing.small)

                    VStack(spacing: AuraSpacing.medium) {
                        // Email/Password button
                        Button {
                            Task {
                                await viewModel.signInWithEmail(email: email, password: password)
                            }
                        } label: {
                            Group {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(viewModel.isSignUpMode ? "Crear Cuenta" : "Iniciar Sesión")
                                }
                            }
                            .font(AuraTypography.bodyStrong)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AuraSpacing.medium)
                            .background(AuraColors.primary)
                            .clipShape(RoundedRectangle(cornerRadius: AuraCorners.medium))
                            .shadow(color: AuraColors.primary.opacity(0.3), radius: 8, y: 4)
                        }
                        .disabled(viewModel.isLoading)

                        dividerRow

                        // Apple Sign In
                        SignInWithAppleButton(
                            .continue,
                            onRequest: { request in
                                request.requestedScopes = [.email, .fullName]
                            },
                            onCompletion: { result in
                                Task {
                                    await viewModel.handleAppleSignIn(result: result)
                                }
                            }
                        )
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: AuraCorners.medium))

                        // Google Sign In
                        Button {
                            Task {
                                await viewModel.signInWithGoogle()
                            }
                        } label: {
                            HStack(spacing: AuraSpacing.small) {
                                Image(systemName: "globe")
                                Text("Continuar con Google")
                            }
                            .font(AuraTypography.bodyStrong)
                            .foregroundStyle(AuraColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AuraSpacing.medium)
                            .background(AuraColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AuraCorners.medium))
                            .shadow(color: AuraColors.shadowCool, radius: 10, y: 4)
                        }
                        .disabled(viewModel.isLoading)
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(AuraTypography.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal, AuraSpacing.small)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, AuraSpacing.xLarge)
                .padding(.bottom, AuraSpacing.xLarge)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.errorMessage)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isSignUpMode)
    }

    private var dividerRow: some View {
        HStack {
            Rectangle().fill(AuraColors.secondary.opacity(0.4)).frame(height: 1)
            Text("o")
                .font(AuraTypography.caption)
                .foregroundStyle(AuraColors.textSecondary)
            Rectangle().fill(AuraColors.secondary.opacity(0.4)).frame(height: 1)
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
                .foregroundStyle(AuraColors.textSecondary)
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
                .foregroundStyle(AuraColors.textSecondary)
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
