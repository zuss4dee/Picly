import SwiftUI

struct ShootCard: View {
    let shoot: Shoot
    
    // Pastel color palette inspired by the design
    private let pastelColors: [Color] = [
        Color(red: 0.95, green: 0.9, blue: 1.0),   // Light Purple
        Color(red: 0.9, green: 0.95, blue: 0.9),   // Light Green
        Color(red: 0.9, green: 0.95, blue: 1.0),   // Light Blue
        Color(red: 0.98, green: 0.96, blue: 0.92), // Light Beige
        Color(red: 1.0, green: 0.92, blue: 0.9),   // Light Peach
        Color(red: 0.95, green: 0.9, blue: 0.95)   // Light Pink
    ]
    
    private var cardColor: Color {
        let index = abs(shoot.id.hashValue) % pastelColors.count
        return pastelColors[index]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail Section
            thumbnailSection
            
            // Content Section
            contentSection
        }
        .background(cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Thumbnail Section
    private var thumbnailSection: some View {
        ZStack {
            // Background placeholder or actual thumbnail
            if let thumbnailData = shoot.thumbnailData,
               let uiImage = UIImage(data: thumbnailData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
                    .clipped()
            } else {
                // Placeholder with icon
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 120)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                    )
            }
            
            // Photo count badge
            VStack {
                HStack {
                    Spacer()
                    photoCountBadge
                }
                Spacer()
            }
            .padding(.top, 8)
            .padding(.trailing, 8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Shoot name
            Text(shoot.name)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Shoot details
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(shoot.formattedCreatedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(shoot.mediaCount) photos")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Media type indicators
                mediaTypeIndicators
            }
        }
        .padding(16)
    }
    
    // MARK: - Photo Count Badge
    private var photoCountBadge: some View {
        Text("\(shoot.mediaCount)")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.7))
            .clipShape(Capsule())
    }
    
    // MARK: - Media Type Indicators
    private var mediaTypeIndicators: some View {
        HStack(spacing: 4) {
            // Photo indicator
            if shoot.mediaAssets.contains(where: { $0.isImage }) {
                Image(systemName: "photo.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            // Video indicator
            if shoot.mediaAssets.contains(where: { $0.isVideo }) {
                Image(systemName: "video.fill")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    let shoot = Shoot(name: "Sample Shoot")
    return ShootCard(shoot: shoot)
        .frame(width: 180, height: 240)
        .padding()
}
