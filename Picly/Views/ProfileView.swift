import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAccountAlert = false
    @State private var isDeletingAccount = false
    @State private var showDeleteErrorAlert = false
    @State private var deleteErrorMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    subscriptionSection
                    actionsSection
                }
                .padding(.top, 16)
                .padding(.bottom, 40)
                .padding(.horizontal, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("My Account")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: authViewModel.isAuthenticated) { _, isAuthenticated in
                if !isAuthenticated { dismiss() }
            }
            .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteAccount()
                    }
                }
            } message: {
                Text("Are you sure you want to delete your account? This action cannot be undone and will permanently remove all your data.")
            }
            .alert("Delete Account Failed", isPresented: $showDeleteErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(deleteErrorMessage)
            }
        }
    }
    
    // MARK: - Actions
    private func deleteAccount() async {
        await MainActor.run {
            isDeletingAccount = true
        }
        
        do {
            print("ProfileView: Starting account deletion...")
            try await authViewModel.deleteAccount()
            print("ProfileView: Account deletion successful")
            
            await MainActor.run {
                isDeletingAccount = false
                dismiss()
            }
        } catch {
            print("ProfileView: Failed to delete account: \(error)")
            
            await MainActor.run {
                isDeletingAccount = false
                deleteErrorMessage = error.localizedDescription
                showDeleteErrorAlert = true
            }
        }
    }
    
    // MARK: - Header (Avatar + Name + Email)
    private var headerSection: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 72, height: 72)
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 38))
                    .foregroundColor(Color(.systemGray))
            }
            VStack(alignment: .leading, spacing: 6) {
                if let user = authViewModel.session?.user {
                    let fullName = user.userMetadata["full_name"]?.description
                    Text((fullName?.isEmpty == false ? fullName : nil) ?? user.email ?? "Signed In")
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                    Text(user.email ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("Not Signed In")
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                }
            }
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Subscription
    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Subscription")
                .font(.headline)
            HStack {
                Label(authViewModel.subscriptionTier == "FREE" ? "FREE Plan" : "Picly Pro", systemImage: "crown")
                    .foregroundColor(.secondary)
                Spacer()
                Link("Manage Subscription", destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
                    .buttonStyle(.bordered)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Actions
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account Actions")
                .font(.headline)
            Button {
                Task { await authViewModel.signOut() }
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Log Out")
                }
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            
            Button(role: .destructive) {
                showDeleteAccountAlert = true
            } label: {
                HStack {
                    if isDeletingAccount {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "trash")
                    }
                    Text(isDeletingAccount ? "Deleting Account..." : "Delete Account")
                }
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .disabled(isDeletingAccount)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
    }
}

#Preview {
    ProfileView().environmentObject(AuthViewModel())
}


