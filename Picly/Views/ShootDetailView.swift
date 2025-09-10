import SwiftUI
import SwiftData
import PhotosUI

struct ShootDetailView: View {
    let shoot: Shoot
    let dataManager: DataManager
    
    @State private var assets: [MediaAsset] = []
    @State private var isLoading = true
    @State private var showSystemCamera = false
    @State private var showPhotosPicker = false
    @State private var selectedPickerItems: [PhotosPickerItem] = []
    @State private var isImporting = false
    @State private var importProgress: Double = 0.0
    @State private var importCount: Int = 0
    
    // Selection state
    @State private var isSelectionMode = false
    @State private var selectedAssets: Set<MediaAsset> = []
    @State private var showBatchDeleteConfirmation = false
    @State private var showBatchShareSheet = false
    
    // Context menu state
    @State private var assetToShare: MediaAsset?
    @State private var assetToDelete: MediaAsset?
    @State private var showShareSheet = false
    @State private var showDeleteConfirmation = false
    
    private let gridColumns = [
        GridItem(.adaptive(minimum: 110), spacing: 8)
    ]
    
    @ViewBuilder
    private var contentView: some View {
        if isLoading || isImporting {
            loadingView
        } else if assets.isEmpty {
            emptyStateView
        } else {
            photosGridView
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Animated loading indicator
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 6)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(isImporting ? 360 : 0))
                    .animation(
                        .linear(duration: 1.0).repeatForever(autoreverses: false),
                        value: isImporting
                    )
            }
            
            VStack(spacing: 8) {
                Text(isImporting ? "Importing Photos..." : "Loading Photos...")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(isImporting ? "Please wait while we process your photos" : "Getting your photos ready")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Enhanced empty state icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 50, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 16) {
                Text("No Photos Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Add photos from your library or take new ones to get started")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private var photosGridView: some View {
        LazyVGrid(columns: gridColumns, spacing: 12) {
            ForEach(assets) { asset in
                photoItemView(for: asset)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }
    
    @ViewBuilder
    private func photoItemView(for asset: MediaAsset) -> some View {
        ZStack {
            if isSelectionMode {
                selectionModeView(for: asset)
            } else {
                normalModeView(for: asset)
            }
        }
    }
    
    private func selectionModeView(for asset: MediaAsset) -> some View {
        Button(action: {
            toggleSelection(for: asset)
        }) {
            ThumbnailView(asset: asset)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(selectedAssets.contains(asset) ? Color.blue : Color.clear, lineWidth: 3)
                )
                .overlay(
                    selectionIndicator(for: asset)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func normalModeView(for asset: MediaAsset) -> some View {
        NavigationLink(destination: PhotoDetailView(assets: assets, currentIndex: assets.firstIndex(of: asset) ?? 0, dataManager: dataManager)) {
            ThumbnailView(asset: asset)
        }
        .contextMenu {
            Button(action: {
                shareImage(asset)
            }) {
                Label("Share...", systemImage: "square.and.arrow.up")
            }
            
            Button(action: {
                deleteImage(asset)
            }) {
                Label("Delete", systemImage: "trash")
            }
            .foregroundColor(.red)
        }
    }
    
    private func selectionIndicator(for asset: MediaAsset) -> some View {
        VStack {
            HStack {
                Spacer()
                Image(systemName: selectedAssets.contains(asset) ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selectedAssets.contains(asset) ? .blue : .white)
                    .background(Circle().fill(Color.black.opacity(0.6)))
                    .font(.title2)
            }
            Spacer()
        }
        .padding(8)
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            contentView
        }
        .navigationTitle(shoot.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if isSelectionMode {
                    // Selection mode toolbar
                    Button("Cancel") {
                        exitSelectionMode()
                    }
                    
                    if !selectedAssets.isEmpty {
                        Button(action: {
                            shareSelectedAssets()
                        }) {
                            ZStack {
                                Image(systemName: "square.and.arrow.up")
                                
                                // Selection count badge
                                Text("\(selectedAssets.count)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 16, height: 16)
                                    .background(Circle().fill(Color.blue))
                                    .offset(x: 8, y: -8)
                            }
                        }
                        
                        Button(action: {
                            showBatchDeleteConfirmation = true
                        }) {
                            ZStack {
                                Image(systemName: "trash")
                                
                                // Selection count badge
                                Text("\(selectedAssets.count)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 16, height: 16)
                                    .background(Circle().fill(Color.red))
                                    .offset(x: 8, y: -8)
                            }
                        }
                        .foregroundColor(.red)
                    }
                } else {
                    // Normal mode toolbar
                    Button(action: {
                        showSystemCamera = true
                    }) {
                        Image(systemName: "camera.fill")
                    }
                    
                    Menu {
                        Button(action: {
                            showPhotosPicker = true
                        }) {
                            Label("Import Photos", systemImage: "photo.on.rectangle")
                        }
                        
                        if !assets.isEmpty {
                            Button(action: {
                                enterSelectionMode()
                            }) {
                                Label("Select Photos", systemImage: "checkmark.circle")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .onAppear(perform: loadAssets)
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
            // Refresh assets when database changes
            Task {
                await MainActor.run {
                    self.assets = self.shoot.mediaAssets
                    print("🔄 Refreshed assets due to database change. Total assets: \(self.assets.count)")
                }
            }
        }
        .fullScreenCover(isPresented: $showSystemCamera) {
            ImagePicker { mediaResult in
                // Handle captured media (image or video)
                Task {
                    await saveMediaToShoot(mediaResult)
                }
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showPhotosPicker) {
            NavigationView {
                ZStack {
                    // Background gradient
                    LinearGradient(
                        colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    
                    if isImporting {
                        // Enhanced loading screen
                        VStack(spacing: 32) {
                            // Animated progress circle
                            ZStack {
                                Circle()
                                    .stroke(Color(.systemGray5), lineWidth: 8)
                                    .frame(width: 120, height: 120)
                                
                                Circle()
                                    .trim(from: 0, to: importProgress)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                    )
                                    .frame(width: 120, height: 120)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.easeInOut(duration: 0.3), value: importProgress)
                                
                                VStack(spacing: 4) {
                                    Text("\(Int(importProgress * 100))%")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    
                                    Text("\(importCount)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            VStack(spacing: 16) {
                                Text("Importing Photos")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text("Processing your photos...")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            
                            // Progress bar
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Progress")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(importCount) of \(selectedPickerItems.count)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                ProgressView(value: importProgress, total: 1.0)
                                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                    .scaleEffect(y: 2)
                            }
                            .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Enhanced photo selection screen
                        VStack(spacing: 40) {
                            Spacer()
                            
                            // Icon with background
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 140, height: 140)
                                
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 50, weight: .light))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            
                            VStack(spacing: 16) {
                                Text("Select Photos")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("Choose up to 20 photos from your library to add to this shoot")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(3)
                                    .padding(.horizontal, 20)
                            }
                            
                            // Enhanced button
                            PhotosPicker(selection: $selectedPickerItems, maxSelectionCount: 20, matching: .images) {
                                HStack(spacing: 12) {
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.system(size: 18, weight: .medium))
                                    
                                    Text("Open Photo Library")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .padding(.horizontal, 40)
                            
                            Spacer()
                        }
                    }
                }
                .navigationTitle("Import Photos")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            showPhotosPicker = false
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .onChange(of: selectedPickerItems) { _, newValue in
                print("🔄 PhotosPicker selection changed: \(newValue.count) items selected")
                Task {
                    await importSelectedMedia(newValue)
                }
            }
        }
        .onChange(of: showShareSheet) { _, shouldShow in
            if shouldShow, let asset = assetToShare {
                presentShareSheet(for: asset)
            }
        }
        .onChange(of: showBatchShareSheet) { _, shouldShow in
            if shouldShow {
                presentBatchShareSheet()
            }
        }
        .alert("Delete Photo", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let asset = assetToDelete {
                    Task {
                        await deleteAsset(asset)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this photo? This action cannot be undone.")
        }
        .alert("Delete Photos", isPresented: $showBatchDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete \(selectedAssets.count) Photos", role: .destructive) {
                Task {
                    await deleteSelectedAssets()
                }
            }
        } message: {
            Text("Are you sure you want to delete \(selectedAssets.count) selected photos? This action cannot be undone.")
        }
    }
    
    private func loadAssets() {
        print("🔄 Loading assets for shoot: \(shoot.name)")
        isLoading = true
        Task {
            let fetchedAssets = shoot.mediaAssets
            print("📁 Fetched \(fetchedAssets.count) assets from DataManager")
            await MainActor.run {
                self.assets = fetchedAssets
                self.isLoading = false
                print("✅ Updated UI with \(self.assets.count) assets")
            }
        }
    }
    
    private func saveMediaToShoot(_ mediaResult: MediaResult) async {
        do {
            switch mediaResult {
            case .image(let image):
                _ = try await dataManager.createMediaAsset(from: image, for: shoot)
            case .video(let videoURL):
                _ = try await dataManager.createMediaAsset(from: videoURL, for: shoot)
            }
            
            await MainActor.run {
                // Refresh from shoot relationship to ensure consistency
                self.assets = self.shoot.mediaAssets
                print("🔄 Refreshed assets after camera capture. Total assets: \(self.assets.count)")
            }
        } catch {
            print("Failed to save media: \(error)")
        }
    }
    
    private func importSelectedMedia(_ items: [PhotosPickerItem]) async {
        print("📥 Starting to import \(items.count) photos")
        guard !items.isEmpty else { 
            print("❌ No items to import")
            return 
        }
        
        // Show loading state
        await MainActor.run {
            self.isImporting = true
            self.importProgress = 0.0
            self.importCount = 0
        }
        
        // Process photos sequentially to avoid Sendable issues
        var importedAssets: [MediaAsset] = []
        
        for (index, item) in items.enumerated() {
            print("📄 Processing photo \(index + 1) of \(items.count)")
            do {
                // Load as image data only
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    print("✅ Successfully loaded image data: \(image.size.width)x\(image.size.height)")
                    let asset = try await dataManager.createMediaAssetOptimized(from: image, for: shoot)
                    importedAssets.append(asset)
                } else {
                    print("❌ Failed to load item as image data")
                }
            } catch {
                print("❌ Failed to import photo \(index + 1): \(error)")
            }
            
            // Update progress
            await MainActor.run {
                self.importCount += 1
                self.importProgress = Double(self.importCount) / Double(items.count)
            }
        }
        
        print("📊 Successfully imported \(importedAssets.count) out of \(items.count) photos")
        
        // Batch save all assets at once for better performance
        do {
            try dataManager.batchSaveAssets(importedAssets)
            print("💾 Batch saved \(importedAssets.count) assets to database")
        } catch {
            print("❌ Failed to batch save assets: \(error)")
        }
        
        // Update UI once at the end
        await MainActor.run {
            self.assets = self.shoot.mediaAssets
            self.selectedPickerItems = []
            self.isImporting = false
            self.showPhotosPicker = false
            print("🔄 Import complete. Total assets: \(self.assets.count)")
        }
    }
    
    // MARK: - Context Menu Actions
    private func shareImage(_ asset: MediaAsset) {
        print("📤 Sharing image: \(asset.fileName)")
        assetToShare = asset
        showShareSheet = true
    }
    
    private func presentShareSheet(for asset: MediaAsset) {
        Task {
            do {
                let fileURL = URL(fileURLWithPath: asset.localFilePath)
                let imageData = try Data(contentsOf: fileURL)
                
                if let image = UIImage(data: imageData) {
                    await MainActor.run {
                        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
                        
                        // Present the share sheet
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            window.rootViewController?.present(activityViewController, animated: true)
                        }
                        
                        // Reset the state
                        self.showShareSheet = false
                        self.assetToShare = nil
                    }
                    print("✅ Successfully presented share sheet for image: \(image.size)")
                } else {
                    print("❌ Failed to create UIImage from data")
                    await MainActor.run {
                        self.showShareSheet = false
                        self.assetToShare = nil
                    }
                }
            } catch {
                print("❌ Failed to load image for sharing: \(error)")
                await MainActor.run {
                    self.showShareSheet = false
                    self.assetToShare = nil
                }
            }
        }
    }
    
    private func deleteImage(_ asset: MediaAsset) {
        print("🗑️ Requesting deletion of: \(asset.fileName)")
        assetToDelete = asset
        showDeleteConfirmation = true
    }
    
    private func deleteAsset(_ asset: MediaAsset) async {
        print("🗑️ Deleting asset: \(asset.fileName)")
        do {
            try dataManager.deleteMediaAsset(asset)
            self.assets = self.shoot.mediaAssets
            print("✅ Successfully deleted asset. Remaining assets: \(self.assets.count)")
        } catch {
            print("❌ Failed to delete asset: \(error)")
        }
    }
    
    // MARK: - Selection Mode Functions
    
    private func enterSelectionMode() {
        print("📝 Entering selection mode")
        isSelectionMode = true
        selectedAssets.removeAll()
    }
    
    private func exitSelectionMode() {
        print("📝 Exiting selection mode")
        isSelectionMode = false
        selectedAssets.removeAll()
    }
    
    private func toggleSelection(for asset: MediaAsset) {
        if selectedAssets.contains(asset) {
            selectedAssets.remove(asset)
            print("➖ Deselected: \(asset.fileName)")
        } else {
            selectedAssets.insert(asset)
            print("➕ Selected: \(asset.fileName)")
        }
    }
    
    private func deleteSelectedAssets() async {
        print("🗑️ Deleting \(selectedAssets.count) selected assets")
        let assetsToDelete = Array(selectedAssets)
        
        for asset in assetsToDelete {
            do {
                try dataManager.deleteMediaAsset(asset)
                print("✅ Deleted: \(asset.fileName)")
            } catch {
                print("❌ Failed to delete \(asset.fileName): \(error)")
            }
        }
        
        self.assets = self.shoot.mediaAssets
        self.selectedAssets.removeAll()
        self.isSelectionMode = false
        print("🔄 Batch delete complete. Remaining assets: \(self.assets.count)")
    }
    
    private func shareSelectedAssets() {
        print("📤 Sharing \(selectedAssets.count) selected assets")
        showBatchShareSheet = true
    }
    
    private func presentBatchShareSheet() {
        Task {
            do {
                var imagesToShare: [UIImage] = []
                
                for asset in selectedAssets {
                    let fileURL = URL(fileURLWithPath: asset.localFilePath)
                    let imageData = try Data(contentsOf: fileURL)
                    if let image = UIImage(data: imageData) {
                        imagesToShare.append(image)
                    }
                }
                
                await MainActor.run {
                    let activityVC = UIActivityViewController(activityItems: imagesToShare, applicationActivities: nil)
                    
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.rootViewController?.present(activityVC, animated: true)
                    }
                    
                    // Reset states
                    self.showBatchShareSheet = false
                    self.selectedAssets.removeAll()
                    self.isSelectionMode = false
                    print("📤 Batch share sheet presented with \(imagesToShare.count) images")
                }
            } catch {
                print("❌ Failed to prepare batch share: \(error)")
                await MainActor.run {
                    self.showBatchShareSheet = false
                }
            }
        }
    }
}

#Preview {
    let modelContainer = try! ModelContainer(for: Shoot.self, MediaAsset.self)
    let sampleShoot = Shoot(name: "Sample Shoot")
    let dataManager = DataManager(modelContext: modelContainer.mainContext)
    
    return NavigationView {
        ShootDetailView(shoot: sampleShoot, dataManager: dataManager)
    }
    .modelContainer(modelContainer)
}