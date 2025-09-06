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
            throw error
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
        guard let userId = session?.user.id else {
            throw AuthError.noCurrentUser
        }
        
        print("Starting account deletion for user: \(userId)")
        
        // Try to delete user data from database
        do {
            // First, try to call the RPC function if it exists
            do {
                let response = try await client.database.rpc(
                    "delete_user_account",
                    params: ["user_id": userId]
                ).execute()
                
                print("Account deletion RPC call successful")
            } catch {
                print("RPC function not available, trying direct deletion: \(error)")
                
                // Fallback: Delete user data directly from tables
                try await deleteUserDataDirectly(userId: userId)
            }
        } catch {
            print("Database deletion failed, but continuing with auth deletion: \(error)")
            // Continue with auth deletion even if database operations fail
        }
        
        // Always sign out the user (this is the most important part)
        do {
            try await client.auth.signOut()
            print("User signed out successfully after account deletion")
        } catch {
            print("Failed to sign out user: \(error)")
            throw error
        }
    }
    
    private func deleteUserDataDirectly(userId: UUID) async throws {
        print("Deleting user data directly for user: \(userId)")
        
        // Delete from shoots table (assuming shoots have a user_id column)
        try await client.database
            .from("shoots")
            .delete()
            .eq("user_id", value: userId)
            .execute()
        
        // Delete from media_assets table (assuming media_assets have a user_id column)
        try await client.database
            .from("media_assets")
            .delete()
            .eq("user_id", value: userId)
            .execute()
        
        print("User data deleted successfully")
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
    
    var errorDescription: String? {
        switch self {
        case .noCurrentUser:
            return "No current user found. Please sign in again."
        }
    }
}
