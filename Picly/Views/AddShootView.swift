import SwiftUI
import SwiftData

struct AddShootView: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var shootName = ""
    @State private var isCreating = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Form
                formSection
                
                Spacer()
                
                // Create Button
                createButton
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                Text("New Shoot")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Invisible button for balance
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.clear)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            Divider()
        }
    }
    
    // MARK: - Form Section
    private var formSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Shoot name input
            VStack(alignment: .leading, spacing: 8) {
                Text("Shoot Name")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                TextField("Enter shoot name...", text: $shootName)
                    .textFieldStyle(CustomTextFieldStyle())
                    .autocapitalization(.words)
                    .disableAutocorrection(true)
            }
            
            // Info section
            VStack(alignment: .leading, spacing: 16) {
                Text("What is a Shoot?")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 12) {
                    infoRow(
                        icon: "square.stack.3d.up.fill",
                        title: "Session-Based Workflow",
                        description: "Every photoshoot gets its own private workspace. No more mixing client work with personal photos."
                    )
                    
                    infoRow(
                        icon: "photo.on.rectangle.angled",
                        title: "A Clutter-Free Camera Roll",
                        description: "Photos you take with Picly save directly into your shoot, keeping your main photo library clean and reserved for your memories."
                    )
                    
                    infoRow(
                        icon: "arrow.up.doc.on.clipboard",
                        title: "Export & Publish Ready",
                        description: "Organize your selects, mark your finals, and export only what you need. Go from photoshoot to post-ready in record time."
                    )
                }
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 32)
    }
    
    // MARK: - Create Button
    private var createButton: some View {
        VStack(spacing: 16) {
            Button(action: createShoot) {
                HStack {
                    if isCreating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    
                    Text(isCreating ? "Creating..." : "Create Shoot")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(shootName.isEmpty ? Color.gray : Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(shootName.isEmpty || isCreating)
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - Helper Views
    private func infoRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Actions
    private func createShoot() {
        guard !shootName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isCreating = true
        
        Task {
            do {
                let trimmedName = shootName.trimmingCharacters(in: .whitespacesAndNewlines)
                _ = try dataManager.createShoot(name: trimmedName)
                
                await MainActor.run {
                    isCreating = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    errorMessage = "Failed to create shoot: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
    }
}

#Preview {
    AddShootView(dataManager: DataManager(modelContext: try! ModelContainer(for: Shoot.self, MediaAsset.self).mainContext))
}
