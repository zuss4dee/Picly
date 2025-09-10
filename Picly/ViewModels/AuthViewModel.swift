import Foundation
import Supabase
import AuthenticationServices
import UIKit

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var session: Session?
    @Published var subscriptionTier: String = "FREE"
    
    private let client = supabase
    private let appleRedirectURL = URL(string: "com.adeosun.Picly://login-callback/")!
    init() {
        // Check initial session
        Task {
            await checkCurrentSession()
        }
        // Set up auth state listener
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        Task {
            for await (event, session) in client.auth.authStateChanges {
                await MainActor.run {
                    self.handleAuthStateChange(event: event, session: session)
                }
            }
        }
    }
    
    private func handleAuthStateChange(event: AuthChangeEvent, session: Session?) {
        switch event {
        case .signedIn, .tokenRefreshed:
            self.session = session
            self.isAuthenticated = session != nil
            print("User signed in - Session: \(session?.user.email ?? "unknown")")
            
        case .signedOut, .userDeleted:
            self.session = nil
            self.isAuthenticated = false
            print("User signed out")
            
        case .passwordRecovery, .mfaChallengeVerified:
            // Handle other auth events if needed
            break
            
        default:
            break
        }
    }
    
    private func checkCurrentSession() async {
        do {
            let currentSession = try await client.auth.session
            await MainActor.run {
                self.session = currentSession
                self.isAuthenticated = true
                let email = currentSession.user.email ?? "unknown"
                print("Current session found: \(email)")
            }
        } catch {
            await MainActor.run {
                self.session = nil
                self.isAuthenticated = false
                print("No current session: \(error.localizedDescription)")
            }
        }
    }
    
    func signInWithApple() {
        Task {
            do {
                _ = try await client.auth.signInWithOAuth(
                    provider: .apple,
                    redirectTo: appleRedirectURL
                )
                // Note: The actual session will be set by the auth state listener
                print("Apple sign-in initiated successfully")
            } catch {
                print("Sign in with Apple (OAuth) failed: \(error)")
                print("Full error details: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Email/Password Auth
    func signUp(email: String, password: String) async throws {
        do {
            _ = try await client.auth.signUp(email: email, password: password)
            // Confirmation email is sent by Supabase; session may be nil until confirmed
        } catch {
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        do {
            _ = try await client.auth.signIn(email: email, password: password)
            // Auth state listener will update session/isAuthenticated
        } catch {
            // Debug: Print the actual error to see what we're getting
            print("🔍 Sign-in error: \(error)")
            print("🔍 Error localized description: \(error.localizedDescription)")
            
            // Check if it's the specific "Invalid login credentials" error
            if let authError = error as? AuthError {
                throw authError
            } else if error.localizedDescription.contains("Invalid login credentials") {
                throw AuthError.userNotFound
            } else if error.localizedDescription.contains("Email not confirmed") ||
                      error.localizedDescription.contains("email_not_confirmed") ||
                      error.localizedDescription.contains("Email not confirmed") ||
                      error.localizedDescription.contains("email address not confirmed") ||
                      error.localizedDescription.contains("Please confirm your email") {
                throw AuthError.emailNotConfirmed
            } else {
                // For all other errors, throw a generic user-friendly error
                throw AuthError.genericSignInError
            }
        }
    }

    func signOut() async {
        do {
            try await client.auth.signOut()
            // Note: The actual session clearing will be handled by the auth state listener
            print("Sign out initiated successfully")
        } catch {
            print("Sign out failed: \(error)")
        }
    }
    
    func deleteAccount() async throws {
        print("AuthViewModel: deleteAccount() function started.")
        do {
            print("AuthViewModel: Attempting to call RPC 'delete_user' on Supabase...")
            _ = try client.rpc("delete_user")
            print("✅ SUCCESS: RPC 'delete_user' was called without error. The auth state listener should now handle the logout.")
            
            // The RPC should trigger the auth state listener to sign out the user
            // But let's also explicitly sign out to ensure it happens
            print("AuthViewModel: Explicitly signing out user...")
            try await client.auth.signOut()
            print("✅ SUCCESS: User signed out successfully after account deletion")
            
        } catch {
            print("❌ FATAL ERROR in deleteAccount(): The RPC call failed.")
            print("   Error Details: \(error)")
            print("   Localized Description: \(error.localizedDescription)")
            throw error
        }
    }
    
    
    private static func presentationAnchor() async -> ASPresentationAnchor {
        await MainActor.run {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow } ?? UIWindow()
        }
    }
}

// MARK: - Auth Errors
enum AuthError: Error, LocalizedError {
    case noCurrentUser
    case userNotFound
    case emailNotConfirmed
    case genericSignInError
    case accountDeletionIncomplete
    case sessionMissing
    
    var errorDescription: String? {
        switch self {
        case .noCurrentUser:
            return "No current user found. Please sign in again."
        case .userNotFound:
            return "Account not found. Would you like to create a new account?"
        case .emailNotConfirmed:
            return "Please check your inbox and confirm your email address before signing in."
        case .genericSignInError:
            return "Sign in failed. Please check your credentials and try again."
        case .accountDeletionIncomplete:
            return "Account deletion was partially completed. Your local data has been deleted, but you may need to contact support to fully remove your account."
        case .sessionMissing:
            return "No active session found. Please sign in again before deleting your account."
        }
    }
}
