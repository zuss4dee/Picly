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
    
    private static func presentationAnchor() async -> ASPresentationAnchor {
        await MainActor.run {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow } ?? UIWindow()
        }
    }
}
