import SwiftUI

struct ThumbnailView: View {
    let asset: MediaAsset
    @State private var originalImage: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            Group {
                if let image = originalImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if isLoading {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.8)
                        )
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: asset.isVideo ? "video" : "photo")
                                .foregroundColor(.gray)
                        )
                }
            }
            .frame(width: 110, height: 110)
            .clipped()
            .cornerRadius(8)
            
            // Video indicator
            if asset.isVideo {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                            .padding(4)
                    }
                }
            }
        }
        .onAppear {
            loadOriginalImage()
        }
    }
    
    private func loadOriginalImage() {
        Task {
            do {
                let fileURL = URL(fileURLWithPath: asset.localFilePath)
                let imageData = try Data(contentsOf: fileURL)
                if let image = UIImage(data: imageData) {
                    await MainActor.run {
                        self.originalImage = image
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.isLoading = false
                    }
                }
            } catch {
                print("Failed to load original image: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

#Preview {
    ThumbnailView(asset: MediaAsset(fileName: "sample.jpg", fileSize: 1024, mediaType: .photo, localFilePath: ""))
}
