import SwiftUI
import SwiftData

struct PhotoDetailView: View {
    let assets: [MediaAsset]
    let currentIndex: Int
    let dataManager: DataManager
    
    @State private var currentTabIndex: Int
    @State private var fullImages: [Int: UIImage] = [:]
    @State private var showShareSheet = false
    @State private var showDeleteAlert = false
    @State private var isPreparingShare = false
    @State private var isDeleting = false
    
    init(assets: [MediaAsset], currentIndex: Int, dataManager: DataManager) {
        self.assets = assets
        self.currentIndex = currentIndex
        self.dataManager = dataManager
        self._currentTabIndex = State(initialValue: currentIndex)
    }
    
    private var currentAsset: MediaAsset? {
        guard currentTabIndex < assets.count else { return nil }
        return assets[currentTabIndex]
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            TabView(selection: $currentTabIndex) {
                ForEach(Array(assets.enumerated()), id: \.element.id) { index, asset in
                    photoContentView(for: asset, at: index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onChange(of: currentTabIndex) { _, newIndex in
                Task {
                    await loadImageForIndex(newIndex)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.black)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // Share button
                Button(action: {
                    shareCurrentAsset()
                }) {
                    if isPreparingShare {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                .disabled(isPreparingShare || isDeleting)
                
                // Delete button
                Button(action: {
                    showDeleteAlert = true
                }) {
                    if isDeleting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "trash")
                    }
                }
                .disabled(isPreparingShare || isDeleting)
            }
        }
        .task { 
            await loadImageForIndex(currentTabIndex)
        }
        .onChange(of: showShareSheet) { _, shouldShow in
            if shouldShow {
                shareCurrentAsset()
            }
        }
        .alert("Delete Photo", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteCurrentAsset()
                }
            }
        } message: {
            Text("Are you sure you want to delete this photo? This action cannot be undone.")
        }
    }
    
    @ViewBuilder
    private func photoContentView(for asset: MediaAsset, at index: Int) -> some View {
        Group {
            if let image = fullImages[index] {
                ZoomableImageView(image: image)
                    .transition(.opacity)
            } else if let placeholder = placeholderImageForAsset(asset) {
                Image(uiImage: placeholder)
                    .resizable()
                    .scaledToFit()
                    .opacity(0.85)
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
    }
    
    private func placeholderImageForAsset(_ asset: MediaAsset) -> UIImage? {
        if let thumb = asset.thumbnailData {
            return UIImage(data: thumb)
        }
        return nil
    }
    
    private func loadImageForIndex(_ index: Int) async {
        guard index < assets.count else { return }
        guard fullImages[index] == nil else { return }
        
        let asset = assets[index]
        let path = asset.localFilePath
        
        do {
            let url = URL(fileURLWithPath: path)
            let data = try Data(contentsOf: url, options: [.mappedIfSafe])
            if let image = UIImage(data: data) {
                print("📸 Loaded full resolution image: \(image.size.width)x\(image.size.height) for asset \(index)")
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.fullImages[index] = image
                    }
                }
            }
        } catch {
            // Fallback to direct file loading
            if let image = UIImage(contentsOfFile: path) {
                print("📸 Loaded full resolution image (fallback): \(image.size.width)x\(image.size.height) for asset \(index)")
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.fullImages[index] = image
                    }
                }
            }
        }
    }
    
    // MARK: - Action Functions
    
    private func shareCurrentAsset() {
        guard let asset = currentAsset else { return }
        
        Task {
            await MainActor.run {
                isPreparingShare = true
            }
            
            // Load the full resolution image
            do {
                let url = URL(fileURLWithPath: asset.localFilePath)
                let data = try Data(contentsOf: url, options: [.mappedIfSafe])
                
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        presentShareSheet(for: asset, with: image)
                        isPreparingShare = false
                    }
                } else {
                    await MainActor.run {
                        isPreparingShare = false
                    }
                }
            } catch {
                // Fallback to direct file loading
                if let image = UIImage(contentsOfFile: asset.localFilePath) {
                    await MainActor.run {
                        presentShareSheet(for: asset, with: image)
                        isPreparingShare = false
                    }
                } else {
                    await MainActor.run {
                        isPreparingShare = false
                    }
                }
            }
        }
    }
    
    private func presentShareSheet(for asset: MediaAsset, with image: UIImage) {
        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityViewController, animated: true)
        }
    }
    
    private func deleteCurrentAsset() async {
        guard let asset = currentAsset else { return }
        
        await MainActor.run {
            isDeleting = true
        }
        
        do {
            try dataManager.deleteMediaAsset(asset)
            
            await MainActor.run {
                isDeleting = false
                // Navigate back or handle deletion
                // The parent view should handle refreshing the assets list
            }
        } catch {
            print("❌ Failed to delete asset: \(error)")
            await MainActor.run {
                isDeleting = false
            }
        }
    }
}

#Preview {
    let sampleAsset = MediaAsset(fileName: "demo.jpg", fileSize: 0, mediaType: .photo, localFilePath: "")
    let dataManager = DataManager(modelContext: ModelContext(try! ModelContainer(for: MediaAsset.self, Shoot.self)))
    PhotoDetailView(assets: [sampleAsset], currentIndex: 0, dataManager: dataManager)
}