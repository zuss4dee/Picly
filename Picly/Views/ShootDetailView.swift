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
        VStack {
            Spacer(minLength: 40)
            ProgressView(isImporting ? "Importing photos..." : "Loading photos...")
            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No photos yet")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Add photos from your library or take new ones")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 300)
    }
    
    private var photosGridView: some View {
        LazyVGrid(columns: gridColumns, spacing: 8) {
            ForEach(assets) { asset in
                photoItemView(for: asset)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
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
                            Label("Import from Library", systemImage: "photo.on.rectangle")
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
                VStack(spacing: 20) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Select Photos & Videos")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("Choose up to 10 photos or videos from your library")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    PhotosPicker(selection: $selectedPickerItems, maxSelectionCount: 10, matching: .any(of: [.images, .videos])) {
                        Text("Open Photo Library")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .navigationTitle("Import Media")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            showPhotosPicker = false
                        }
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
            do {
                let fetchedAssets = shoot.mediaAssets
                print("📁 Fetched \(fetchedAssets.count) assets from DataManager")
                await MainActor.run {
                    self.assets = fetchedAssets
                    self.isLoading = false
                    print("✅ Updated UI with \(self.assets.count) assets")
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
                print("❌ Failed to load assets: \(error)")
            }
        }
    }
    
    private func saveMediaToShoot(_ mediaResult: MediaResult) async {
        do {
            let asset: MediaAsset
            switch mediaResult {
            case .image(let image):
                asset = try await dataManager.createMediaAsset(from: image, for: shoot)
            case .video(let videoURL):
                asset = try await dataManager.createMediaAsset(from: videoURL, for: shoot)
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
        print("📥 Starting to import \(items.count) media items")
        guard !items.isEmpty else { 
            print("❌ No items to import")
            return 
        }
        
        // Show loading state
        await MainActor.run {
            self.isImporting = true
        }
        
        var importedAssets: [MediaAsset] = []
        
        for (index, item) in items.enumerated() {
            print("📄 Processing item \(index + 1) of \(items.count)")
            do {
                // Try to load as image first
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    print("✅ Successfully loaded image data: \(image.size.width)x\(image.size.height)")
                    let asset = try await dataManager.createMediaAsset(from: image, for: shoot)
                    importedAssets.append(asset)
                }
                // If not an image, try to load as video URL
                else if let videoURL = try await item.loadTransferable(type: URL.self) {
                    print("✅ Successfully loaded video URL, creating MediaAsset...")
                    let asset = try await dataManager.createMediaAsset(from: videoURL, for: shoot)
                    importedAssets.append(asset)
                } else {
                    print("❌ Failed to load item as either image data or video URL")
                }
            } catch {
                print("❌ Failed to import media item \(index + 1): \(error)")
            }
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
            try await dataManager.deleteMediaAsset(asset)
            await MainActor.run {
                self.assets = self.shoot.mediaAssets
                print("✅ Successfully deleted asset. Remaining assets: \(self.assets.count)")
            }
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
                try await dataManager.deleteMediaAsset(asset)
                print("✅ Deleted: \(asset.fileName)")
            } catch {
                print("❌ Failed to delete \(asset.fileName): \(error)")
            }
        }
        
        await MainActor.run {
            self.assets = self.shoot.mediaAssets
            self.selectedAssets.removeAll()
            self.isSelectionMode = false
            print("🔄 Batch delete complete. Remaining assets: \(self.assets.count)")
        }
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