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
                        .fill(
                            LinearGradient(
                                colors: [Color(.systemGray6), Color(.systemGray5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            VStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.blue)
                                
                                Text("Loading...")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        )
                } else {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(.systemGray6), Color(.systemGray5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            VStack(spacing: 4) {
                                Image(systemName: asset.isVideo ? "video.fill" : "photo.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.secondary)
                                
                                Text(asset.isVideo ? "Video" : "Photo")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        )
                }
            }
            .frame(width: 110, height: 110)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            
            // Video indicator
            if asset.isVideo {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.7))
                                    .frame(width: 24, height: 24)
                            )
                            .padding(6)
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
                // For videos, use the pre-generated thumbnail data
                if asset.isVideo {
                    if let thumbnailData = asset.thumbnailData,
                       let thumbnailImage = UIImage(data: thumbnailData) {
                        await MainActor.run {
                            self.originalImage = thumbnailImage
                            self.isLoading = false
                        }
                    } else {
                        await MainActor.run {
                            self.isLoading = false
                        }
                    }
                } else {
                    // For photos, load the original image file
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
