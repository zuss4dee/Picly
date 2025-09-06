import SwiftUI

struct ShootInfoView: View {
    let shoot: Shoot
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Project Details") {
                    InfoRow(title: "Name", value: shoot.name)
                    InfoRow(title: "Created", value: shoot.formattedCreatedDate)
                    InfoRow(title: "Last Updated", value: shoot.formattedUpdatedDate)
                }
                
                Section("Content") {
                    InfoRow(title: "Total Photos", value: "\(shoot.mediaCount)")
                    InfoRow(title: "Total Size", value: formattedTotalSize)
                }
                
                if !shoot.mediaAssets.isEmpty {
                    Section("Recent Activity") {
                        if let latestDate = shoot.latestMediaDate {
                            InfoRow(title: "Latest Photo", value: formatDate(latestDate))
                        }
                    }
                }
            }
            .navigationTitle("Project Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var formattedTotalSize: String {
        let totalBytes = shoot.mediaAssets.reduce(0) { $0 + $1.fileSize }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalBytes)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    ShootInfoView(shoot: Shoot(name: "Sample Project"))
}
