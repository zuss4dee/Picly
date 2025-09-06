import Foundation
import SwiftData

@Model
final class Shoot {
    // MARK: - Properties
    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var isActive: Bool
    var thumbnailData: Data?
    
    // MARK: - Relationships
    var mediaAssets: [MediaAsset]
    
    // MARK: - Initializer
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isActive = true
        self.thumbnailData = nil
        self.mediaAssets = []
    }
    
    // MARK: - Computed Properties
    var mediaCount: Int {
        mediaAssets.count
    }
    
    var latestMediaDate: Date? {
        mediaAssets.max(by: { $0.createdAt < $1.createdAt })?.createdAt
    }
    
    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: createdAt)
    }
    
    var formattedUpdatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: updatedAt)
    }
}

// MARK: - Extensions
extension Shoot /* Identifiable via `id` */: Identifiable {}

extension Shoot {
    func addMediaAsset(_ asset: MediaAsset) {
        mediaAssets.append(asset)
        updatedAt = Date()
    }
    
    func removeMediaAsset(_ asset: MediaAsset) {
        mediaAssets.removeAll { $0.id == asset.id }
        updatedAt = Date()
    }
    
    func updateThumbnail() {
        // Update thumbnail from the most recent media asset
        if let latestAsset = mediaAssets.max(by: { $0.createdAt < $1.createdAt }) {
            thumbnailData = latestAsset.thumbnailData
        }
    }
}
