import SwiftUI
import SwiftData
import SuperwallKit
import Zip

struct ShootsDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var dataManager: DataManager
    @State private var shoots: [Shoot] = []
    @State private var showingAddShoot = false
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var showDeleteAlert = false
    @State private var shootPendingDeletion: Shoot?
    @State private var showRenameAlert = false
    @State private var renameText: String = ""
    @State private var showInfoSheet = false
    @State private var selectedShootForInfo: Shoot?
    @State private var itemsToShare: [UIImage]?
    @State private var isPreparingToShare = false
    @State private var showShareSheet = false
    @State private var selectedShootForShare: Shoot?
    
    init(modelContext: ModelContext) {
        self._dataManager = StateObject(wrappedValue: DataManager(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        searchBar
                        
                        if isLoading {
                            loadingSection
                        } else if filteredShoots.isEmpty {
                            emptyState
                        } else {
                            gridSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 120)
                }
                
                floatingAddButton
                
                // Progress overlay for sharing
                if isPreparingToShare {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Preparing images...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(24)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(12)
                }
            }
            .background(Color(.systemGroupedBackground))
            .onAppear { loadShoots() }
            .sheet(isPresented: $showingAddShoot, onDismiss: loadShoots) {
                AddShootView(dataManager: dataManager)
            }
            .navigationBarHidden(true)
            .alert("Delete Project?", isPresented: $showDeleteAlert, presenting: shootPendingDeletion) { shoot in
                Button("Delete", role: .destructive) {
                    Task { await performDelete(shoot) }
                }
                Button("Cancel", role: .cancel) { shootPendingDeletion = nil }
            } message: { shoot in
                Text("This will delete ‘\(shoot.name)’ and all its photos from your device.")
            }
            .alert("Rename Project", isPresented: $showRenameAlert) {
                TextField("Project Name", text: $renameText)
                Button("Save") { Task { await performRename() } }
                Button("Cancel", role: .cancel) { shootPendingDeletion = nil }
            }
            .sheet(isPresented: $showInfoSheet) {
                if let shoot = selectedShootForInfo {
                    ShootInfoView(shoot: shoot)
                }
            }
            .onChange(of: showShareSheet) { _, shouldShow in
                if shouldShow, let images = itemsToShare, let shoot = selectedShootForShare {
                    presentShareSheet(for: images, shoot: shoot)
                }
            }
        }
    }
    
    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Projects")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(Color.primary)
            
            if authViewModel.subscriptionTier.uppercased() != "PRO" {
                Text("\(min(shoots.count, 3))/3 projects")
                    .font(.subheadline)
                    .foregroundColor(Color.secondary)
            }
        }
        .padding(.top, 6)
    }
    
    // MARK: - Search
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(.systemGray))
            TextField("Search projects...", text: $searchText)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("No projects yet")
                .font(.title2).bold()
                .foregroundColor(Color(.label))
            Text("Create your first project to start\norganizing your content")
                .font(.body)
                .foregroundColor(Color.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
    
    private var loadingSection: some View {
        HStack { Spacer(); ProgressView(); Spacer() }
            .padding(.top, 80)
    }
    
    // MARK: - Grid
    private var gridSection: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
            ForEach(filteredShoots) { shoot in
                NavigationLink(destination: ShootDetailView(shoot: shoot, dataManager: dataManager)) {
                    ShootCard(shoot: shoot)
                        .contextMenu {
                            Button(action: { beginRename(shoot) }) {
                                Label("Rename", systemImage: "pencil")
                            }
                            Button(action: { 
                                Task {
                                    await prepareToShare(shoot)
                                }
                            }) {
                                Label("Share...", systemImage: "square.and.arrow.up")
                            }
                            Button(action: { showInfoForShoot(shoot) }) {
                                Label("View Info", systemImage: "info.circle")
                            }
                            Divider()
                            Button(role: .destructive, action: { confirmDelete(shoot) }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var filteredShoots: [Shoot] {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return shoots }
        return shoots.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    // MARK: - Floating Button
    private var floatingAddButton: some View {
        Button(action: onTapAdd) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 6)
        }
        .padding(.trailing, 24)
        .padding(.bottom, 24)
    }
    
    // MARK: - Data
    private func loadShoots() {
        isLoading = true
        Task {
            do {
                let fetchedShoots = try dataManager.fetchActiveShoots()
                print("📊 Loaded \(fetchedShoots.count) shoots")
                for shoot in fetchedShoots {
                    print("📁 Shoot '\(shoot.name)' has \(shoot.mediaAssets.count) media assets")
                }
                await MainActor.run {
                    self.shoots = fetchedShoots
                    self.isLoading = false
                }
            } catch {
                await MainActor.run { self.isLoading = false }
            }
        }
    }

    private func onTapAdd() {
        let isPro = authViewModel.subscriptionTier.uppercased() == "PRO"
        let underLimit = shoots.count < 3
        if isPro || underLimit {
            showingAddShoot = true
        } else {
            Superwall.shared.register(placement: "campaign_trigger")
        }
    }

    private func confirmDelete(_ shoot: Shoot) {
        shootPendingDeletion = shoot
        showDeleteAlert = true
    }
    
    private func performDelete(_ shoot: Shoot) async {
        do {
            try dataManager.deleteShoot(shoot)
            await MainActor.run { self.shoots.removeAll { $0.id == shoot.id } }
        } catch {
            // Optionally show an error toast
        }
        await MainActor.run {
            shootPendingDeletion = nil
            showDeleteAlert = false
        }
    }
    
    private func beginRename(_ shoot: Shoot) {
        shootPendingDeletion = shoot
        renameText = shoot.name
        showRenameAlert = true
    }
    
    private func performRename() async {
        guard let shoot = shootPendingDeletion else { return }
        let newName = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newName.isEmpty, newName != shoot.name else {
            showRenameAlert = false
            shootPendingDeletion = nil
            return
        }
        shoot.name = newName
        do {
            try dataManager.updateShoot(shoot)
            await MainActor.run { self.loadShoots() }
        } catch {
            // Optionally show error toast
        }
        await MainActor.run {
            showRenameAlert = false
            shootPendingDeletion = nil
        }
    }
    
    private func getImagesForShoot(_ shoot: Shoot) -> [UIImage] {
        var images: [UIImage] = []
        for asset in shoot.mediaAssets {
            if let image = UIImage(contentsOfFile: asset.localFilePath) {
                images.append(image)
            } else if let thumbnailData = asset.thumbnailData, let image = UIImage(data: thumbnailData) {
                images.append(image)
            }
        }
        return images
    }
    
    private func showInfoForShoot(_ shoot: Shoot) {
        selectedShootForInfo = shoot
        showInfoSheet = true
    }
    
    private func prepareToShare(_ shoot: Shoot) async {
        print("🔄 Starting to prepare share for shoot: \(shoot.name)")
        print("🔍 Shoot ID: \(shoot.id)")
        print("🔍 Shoot mediaAssets count: \(shoot.mediaAssets.count)")
        
        // Set loading state
        await MainActor.run {
            isPreparingToShare = true
        }
        
        do {
            // Access MediaAssets directly from the shoot relationship
            let assets = shoot.mediaAssets
            print("📁 Found \(assets.count) assets for shoot: \(shoot.name)")
            
            // Debug: Print details about each asset
            for (index, asset) in assets.enumerated() {
                print("📄 Asset \(index + 1): ID=\(asset.id), Path=\(asset.localFilePath)")
            }
            
            // Load full-resolution images from file system
            var images: [UIImage] = []
            for asset in assets {
                let fileURL = URL(fileURLWithPath: asset.localFilePath)
                if let imageData = try? Data(contentsOf: fileURL),
                   let image = UIImage(data: imageData) {
                    images.append(image)
                    print("✅ Successfully loaded image: \(asset.localFilePath)")
                } else {
                    print("❌ Failed to load image: \(asset.localFilePath)")
                }
            }
            
            print("🖼️ Successfully loaded \(images.count) images out of \(assets.count) assets")
            
            // Add a small delay to allow the progress overlay to show
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Update state and present sheet
            await MainActor.run {
                self.itemsToShare = images // Always set, even if empty
                self.selectedShootForShare = shoot
                self.showShareSheet = true
                self.isPreparingToShare = false
                print("📤 Share sheet should now be presented with \(images.count) images")
            }
        } catch {
            await MainActor.run {
                self.isPreparingToShare = false
            }
            print("❌ Failed to prepare images for sharing: \(error)")
        }
    }
    
    private func presentShareSheet(for images: [UIImage], shoot: Shoot) {
        Task {
            do {
                // Create a temporary directory for the ZIP file
                let tempDir = FileManager.default.temporaryDirectory
                let zipFileName = "\(shoot.name.replacingOccurrences(of: " ", with: "_"))_photos.zip"
                let zipURL = tempDir.appendingPathComponent(zipFileName)
                
                // Create a temporary folder for the images
                let imagesFolder = tempDir.appendingPathComponent("\(shoot.name)_images")
                try FileManager.default.createDirectory(at: imagesFolder, withIntermediateDirectories: true)
                
                // Save images to the temporary folder with original quality
                for (index, image) in images.enumerated() {
                    let fileName = "photo_\(String(format: "%03d", index + 1)).jpg"
                    let imageURL = imagesFolder.appendingPathComponent(fileName)
                    
                    if let imageData = image.jpegData(compressionQuality: 1.0) {
                        try imageData.write(to: imageURL)
                        print("✅ Saved image \(index + 1) to temporary folder")
                    }
                }
                
                // Create ZIP file
                try Zip.zipFiles(paths: [imagesFolder], zipFilePath: zipURL, password: nil, progress: nil)
                print("✅ Created ZIP file: \(zipURL.path)")
                
                // Clean up temporary folder
                try FileManager.default.removeItem(at: imagesFolder)
                
                // Present the share sheet with the ZIP file
                await MainActor.run {
                    let activityViewController = UIActivityViewController(activityItems: [zipURL], applicationActivities: nil)
                    
                    // Present the share sheet
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.rootViewController?.present(activityViewController, animated: true)
                    }
                    
                    // Reset the state
                    self.showShareSheet = false
                    self.itemsToShare = nil
                    self.selectedShootForShare = nil
                }
                
            } catch {
                print("❌ Failed to create ZIP file: \(error)")
                await MainActor.run {
                    self.showShareSheet = false
                    self.itemsToShare = nil
                    self.selectedShootForShare = nil
                }
            }
        }
    }
}

#Preview {
    ShootsDashboardView(modelContext: try! ModelContainer(for: Shoot.self, MediaAsset.self).mainContext)
        .environmentObject(AuthViewModel())
}
