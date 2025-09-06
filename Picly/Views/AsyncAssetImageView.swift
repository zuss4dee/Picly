import SwiftUI

struct AsyncAssetImageView: View {
    let asset: MediaAsset

    var body: some View {
        ZStack {
            // Placeholder color
            Color(.secondarySystemBackground)

            // Thumbnail
            if let thumbnailData = asset.thumbnailData, let uiImage = UIImage(data: thumbnailData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            }
            
            // Asynchronously load the full-resolution image on top
            AsyncImage(url: URL(fileURLWithPath: asset.localFilePath)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                // While the full-res image is loading, the thumbnail underneath will show.
                EmptyView()
            }
        }
    }
}