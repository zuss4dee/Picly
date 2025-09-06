import Foundation
import SwiftData
import UIKit

@Model
final class MediaAsset {
    // MARK: - Properties
    var id: UUID
    var fileName: String
    var fileSize: Int64
    var mediaType: MediaType
    var createdAt: Date
    var isSelected: Bool
    var isExported: Bool
    
    // File paths and data
    var localFilePath: String
    var thumbnailData: Data?
    var metadata: Data? // JSON data for EXIF, location, etc.
    
    // MARK: - Relationships
    var shoot: Shoot?
    
    // MARK: - Initializer
    init(fileName: String, fileSize: Int64, mediaType: MediaType, localFilePath: String) {
        self.id = UUID()
        self.fileName = fileName
        self.fileSize = fileSize
        self.mediaType = mediaType
        self.createdAt = Date()
        self.isSelected = false
        self.isExported = false
        self.localFilePath = localFilePath
        self.thumbnailData = nil
        self.metadata = nil
        self.shoot = nil
    }
    
    // MARK: - Computed Properties
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    var isImage: Bool {
        mediaType == .photo
    }
    
    var isVideo: Bool {
        mediaType == .video
    }
    
    var thumbnailImage: UIImage? {
        guard let thumbnailData = thumbnailData else { return nil }
        return UIImage(data: thumbnailData)
    }
}

// MARK: - MediaType Enum
enum MediaType: Int, Codable, CaseIterable {
    case photo = 0
    case video = 1
    
    var displayName: String {
        switch self {
        case .photo:
            return "Photo"
        case .video:
            return "Video"
        }
    }
    
    var fileExtension: String {
        switch self {
        case .photo:
            return "jpg"
        case .video:
            return "mov"
        }
    }
    
    var mimeType: String {
        switch self {
        case .photo:
            return "image/jpeg"
        case .video:
            return "video/quicktime"
        }
    }
}

// MARK: - Extensions
extension MediaAsset {
    func generateThumbnail() {
        // This will be implemented when we add the camera functionality
        // For now, it's a placeholder
    }
    
    func updateMetadata() {
        // This will be implemented to extract EXIF data, location, etc.
        // For now, it's a placeholder
    }
    
    func markAsExported() {
        isExported = true
    }
    
    func toggleSelection() {
        isSelected.toggle()
    }
}
