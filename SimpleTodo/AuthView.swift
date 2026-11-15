import SwiftUI

enum AuthMode {
    case login
    case signUp
}

struct AuthView: View {
    private enum Field: Hashable {
        case email
        case password
    }

    let authenticate: (AuthMode, String, String) async throws -> Void

    @State private var mode: AuthMode
    @State private var email = ""
    @State private var password = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    init(
        mode: AuthMode = .login,
        authenticate: @escaping (AuthMode, String, String) async throws -> Void
    ) {
        _mode = State(initialValue: mode)
        self.authenticate = authenticate
    }

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSubmit: Bool {
        !trimmedEmail.isEmpty && !password.isEmpty && !isSubmitting
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 14) {
                    Image(systemName: "list.bullet")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.indigo)
                        .frame(width: 52, height: 52)
                        .background(.indigo.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
                        .accessibilityHidden(true)

                    Text(mode == .login ? "Log in" : "Create an account")
                        .font(.largeTitle.bold())
                        .accessibilityAddTraits(.isHeader)
                }

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email").font(.subheadline.weight(.semibold))
                        TextField("you@example.com", text: $email)
                            .accessibilityLabel("Email")
                            .textContentType(.username)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .password }
                            .padding(14)
                            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password").font(.subheadline.weight(.semibold))
                        SecureField("Password", text: $password)
                            .textContentType(mode == .login ? .password : .newPassword)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                            .onSubmit(submit)
                            .padding(14)
                            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .disabled(isSubmitting)

                VStack(alignment: .leading, spacing: 14) {
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    Button(action: submit) {
                        Group {
                            if isSubmitting {
                                ProgressView().tint(.white)
                                    .accessibilityLabel(Text(mode == .login ? "Logging in" : "Creating account"))
                            } else {
                                Text(mode == .login ? "Log In" : "Sign Up")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 28)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!canSubmit)

                    Button(mode == .login ? "Create an account" : "Already have an account? Log in") {
                        mode = mode == .login ? .signUp : .login
                        focusedField = nil
                        password = ""
                        errorMessage = nil
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .disabled(isSubmitting)
                }
            }
            .frame(maxWidth: 420)
            .padding(.horizontal, 24)
            .padding(.vertical, 44)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
    }

    private func submit() {
        guard canSubmit else { return }

        focusedField = nil
        errorMessage = nil
        isSubmitting = true

        Task {
            defer { isSubmitting = false }
            do {
                try await authenticate(mode, trimmedEmail, password)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview("Login") {
    AuthView { _, _, _ in }
        .tint(.indigo)
}

#Preview("Sign Up") {
    AuthView(mode: .signUp) { _, _, _ in }
        .tint(.indigo)
}
