import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
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
                Button("Manage Subscription") {
                    print("Manage Subscription tapped")
                }
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
                print("Delete Account tapped")
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Account")
                }
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
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


