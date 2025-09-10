import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isSigningIn: Bool = false
    @State private var isPasswordVisible: Bool = false
    @State private var errorMessage: String?
    @State private var showConfirmationAlert: Bool = false
    @State private var isSignUpMode: Bool = false
    @State private var showSignUpPrompt: Bool = false
    
    var body: some View {
        ZStack {
            // Light background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo
                Image("PiclyLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .padding(.bottom, 24)
                
                // Welcome text
                Text("Welcome back")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.bottom, 8)
                
                Text("Sign in to your account to continue")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 40)
                
                // Input fields
                VStack(spacing: 16) {
                    // Email field
                    HStack(spacing: 12) {
                        Image(systemName: "envelope")
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        TextField("Email address", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .foregroundColor(.primary)
                        
                        Image(systemName: "square.grid.3x3")
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // Password field
                    HStack(spacing: 12) {
                        Image(systemName: "lock")
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        Group {
                            if isPasswordVisible {
                                TextField("Password", text: $password)
                            } else {
                                SecureField("Password", text: $password)
                            }
                        }
                        .foregroundColor(.primary)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "square.grid.3x3")
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            
                            Button(action: { isPasswordVisible.toggle() }) {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // Confirm password field (only in sign up mode)
                    if isSignUpMode {
                        HStack(spacing: 12) {
                            Image(systemName: "lock")
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            
                            SecureField("Confirm Password", text: $confirmPassword)
                                .foregroundColor(.primary)
                            
                            Image(systemName: "square.grid.3x3")
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 50)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                
                // Forgot password
                HStack {
                    Spacer()
                    Button("Forgot password?") {
                        // Handle forgot password
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                
                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                }
                
                // Sign In button
                Button(action: { isSignUpMode ? signUp() : signIn() }) {
                    HStack {
                        if isSigningIn {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                        }
                        Text(isSigningIn ? (isSignUpMode ? "Creating…" : "Signing In…") : (isSignUpMode ? "Sign Up" : "Sign In"))
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.primary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isSigningIn || email.isEmpty || password.isEmpty || (isSignUpMode && confirmPassword.isEmpty))
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // Divider
                HStack {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(height: 1)
                    
                    Text("or")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                    
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(height: 1)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // Sign in with Apple
                SignInWithAppleButton(.signIn) { _ in
                    authViewModel.signInWithApple()
                } onCompletion: { _ in }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .cornerRadius(12)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                // Mode toggle
                HStack {
                    Text(isSignUpMode ? "Already have an account?" : "Don't have an account?")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Button(isSignUpMode ? "Sign In" : "Sign Up") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isSignUpMode.toggle()
                        }
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                }
                .padding(.top, 24)
                .padding(.bottom, 40)
                
                Spacer()
            }
        }
        .alert("Check Your Email", isPresented: $showConfirmationAlert) {
            Button("OK", role: .cancel) {
                isSignUpMode = false
            }
        } message: {
            Text("We've sent a confirmation link to your email address.")
        }
        .alert("Account Not Found", isPresented: $showSignUpPrompt) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Up") {
                signUp()
            }
        } message: {
            Text("Would you like to create a new account with this email and password?")
        }
    }
    
    // MARK: - Actions
    private func signIn() {
        isSigningIn = true
        errorMessage = nil
        showSignUpPrompt = false
        Task {
            do {
                try await authViewModel.signIn(email: email, password: password)
                await MainActor.run { isSigningIn = false }
            } catch {
                await MainActor.run {
                    isSigningIn = false
                    if let authError = error as? AuthError, authError == .userNotFound {
                        showSignUpPrompt = true
                    } else {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    private func signUp() {
        isSigningIn = true
        errorMessage = nil
        Task {
            do {
                let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
                try await authViewModel.signUp(email: trimmedEmail, password: trimmedPassword)
                await MainActor.run {
                    isSigningIn = false
                    showConfirmationAlert = true
                }
            } catch {
                await MainActor.run {
                    isSigningIn = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    AuthView().environmentObject(AuthViewModel())
}