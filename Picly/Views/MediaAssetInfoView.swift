import SwiftUI

struct MediaAssetInfoView: View {
    let asset: MediaAsset
    
    var body: some View {
        NavigationView {
            List {
                Section("File Details") {
                    InfoRow(title: "Filename", value: asset.fileName)
                    InfoRow(title: "Created", value: asset.formattedCreatedDate)
                    InfoRow(title: "File Size", value: asset.formattedFileSize)
                }
                
                Section("Image Properties") {
                    InfoRow(title: "Resolution", value: imageResolution)
                    InfoRow(title: "Type", value: asset.mediaType.displayName)
                }
                
                if let image = loadImage() {
                    Section("Preview") {
                        HStack {
                            Spacer()
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Photo Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Dismiss will be handled by the sheet presentation
                    }
                }
            }
        }
    }
    
    private var imageResolution: String {
        guard let image = loadImage() else { return "Unknown" }
        let size = image.size
        return "\(Int(size.width)) × \(Int(size.height))"
    }
    
    private func loadImage() -> UIImage? {
        if let image = UIImage(contentsOfFile: asset.localFilePath) {
            return image
        } else if let thumbnailData = asset.thumbnailData, let image = UIImage(data: thumbnailData) {
            return image
        }
        return nil
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
    MediaAssetInfoView(asset: MediaAsset(fileName: "sample.jpg", fileSize: 1024000, mediaType: .photo, localFilePath: ""))
}
