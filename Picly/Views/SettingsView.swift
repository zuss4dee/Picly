import SwiftUI
import SwiftData
import SuperwallKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Live usage via SwiftData
    @Query(filter: #Predicate<Shoot> { $0.isActive == true }) private var liveShoots: [Shoot]
    @Query private var liveAssets: [MediaAsset]
    
    var body: some View {
        let _ = print("--- Settings View Debug ---")
        let _ = print("Is Authenticated: \(authViewModel.isAuthenticated)")
        let _ = print("Session Object: \(String(describing: authViewModel.session))")
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                subtitle
                
                Text("Account")
                    .font(.title3.bold())
                    .padding(.horizontal, 20)
                accountCard
                
                Text("Usage")
                    .font(.title3.bold())
                    .padding(.horizontal, 20)
                usageGrid
                
                upgradeBanner
                
                // Log out moved into ProfileView
            }
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
    }
    
    // MARK: - Header
    private var header: some View {
        Text("Settings")
            .font(.system(size: 36, weight: .bold))
            .foregroundColor(Color.primary)
            .padding(.horizontal, 20)
    }
    
    private var subtitle: some View {
        Text("Manage your account and preferences")
            .font(.body)
            .foregroundColor(.secondary)
            .padding(.horizontal, 20)
    }
    
    // MARK: - Account Card
    private var accountCard: some View {
        NavigationLink(destination: ProfileView().environmentObject(authViewModel)) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 56, height: 56)
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 26))
                        .foregroundColor(Color(.systemGray))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    if let user = authViewModel.session?.user {
                        let fullName = user.userMetadata["full_name"]?.description
                        Text((fullName?.isEmpty == false ? fullName : nil) ?? user.email ?? "Signed In")
                            .font(.headline)
                            .foregroundColor(.primary)
                    } else {
                        Text("Not Signed In")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "crown")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(authViewModel.subscriptionTier == "FREE" ? "FREE Plan" : "Picly Pro")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 20)
    }
    
    // MARK: - Usage Grid
    private var usageGrid: some View {
        HStack(spacing: 20) {
            usageCard(
                icon: "folder",
                iconColor: .blue,
                title: "Projects",
                count: liveShoots.count,
                remainingText: "\(max(0, 3 - liveShoots.count)) remaining"
            )
            usageCard(
                icon: "photo.on.rectangle",
                iconColor: .green,
                title: "Assets",
                count: liveAssets.count,
                remainingText: "500 remaining"
            )
        }
        .padding(.horizontal, 20)
    }
    
    private func usageCard(icon: String, iconColor: Color, title: String, count: Int, remainingText: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            Text("\(count)")
                .font(.title2.bold())
                .foregroundColor(Color(.label))
            Text(title)
                .font(.headline)
                .foregroundColor(Color(.label))
            Text(remainingText)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Upgrade Banner
    private var upgradeBanner: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "crown.fill")
                    .foregroundColor(.orange)
                Text("Upgrade to Pro")
                    .font(.title3.bold())
                    .foregroundColor(Color(.label))
            }
            Text("Get unlimited projects, unlimited assets, and advanced features to supercharge your content workflow.")
                .font(.body)
                .foregroundColor(.secondary)
            
            Button(action: {
                Superwall.shared.register(placement: "campaign_trigger")
            }) {
                Text("Upgrade Now")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.orange.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.orange.opacity(0.35), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Log Out Section
    private var logOutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account Actions")
                .font(.title3.bold())
                .padding(.horizontal, 20)
            
            Button(action: {
                Task {
                    await authViewModel.signOut()
                }
            }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 16, weight: .medium))
                    Text("Log Out")
                        .font(.headline)
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
    // No manual data refresh needed; @Query keeps counts live
}

#Preview {
    SettingsView()
        .modelContainer(for: [Shoot.self, MediaAsset.self])
        .environmentObject(AuthViewModel())
}
