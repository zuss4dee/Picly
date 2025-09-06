import Foundation
import SwiftData
import UIKit
import SwiftUI
import AVFoundation

@MainActor
class DataManager: ObservableObject {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Shoot Operations
    func createShoot(name: String) throws -> Shoot {
        let shoot = Shoot(name: name)
        modelContext.insert(shoot)
        try modelContext.save()
        return shoot
    }
    
    func fetchShoots() throws -> [Shoot] {
        let descriptor = FetchDescriptor<Shoot>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetchActiveShoots() throws -> [Shoot] {
        let descriptor = FetchDescriptor<Shoot>(
            predicate: #Predicate<Shoot> { $0.isActive == true },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func deleteShoot(_ shoot: Shoot) throws {
        // Delete associated media asset files and records first
        for asset in shoot.mediaAssets {
            let path = asset.localFilePath
            if !path.isEmpty {
                let url = URL(fileURLWithPath: path)
                if FileManager.default.fileExists(atPath: url.path) {
                    try? FileManager.default.removeItem(at: url)
                }
            }
            modelContext.delete(asset)
        }
        // Now delete the shoot itself
        modelContext.delete(shoot)
        try modelContext.save()
    }
    
    func updateShoot(_ shoot: Shoot) throws {
        shoot.updatedAt = Date()
        try modelContext.save()
    }
    
    // MARK: - MediaAsset Operations
    func createMediaAsset(
        fileName: String,
        fileSize: Int64,
        mediaType: MediaType,
        localFilePath: String,
        in shoot: Shoot
    ) throws -> MediaAsset {
        let asset = MediaAsset(
            fileName: fileName,
            fileSize: fileSize,
            mediaType: mediaType,
            localFilePath: localFilePath
        )
        
        // Add the asset to the shoot's mediaAssets array
        shoot.addMediaAsset(asset)
        
        modelContext.insert(asset)
        try modelContext.save()
        
        
        return asset
    }
    
    func createMediaAsset(from image: UIImage, for shoot: Shoot) async throws -> MediaAsset {
        // Generate a unique filename
        let fileName = "\(UUID().uuidString).jpg"
        
        // Get the documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let shootDirectory = documentsPath.appendingPathComponent("Shoots").appendingPathComponent(shoot.id.uuidString)
        
        // Create shoot directory if it doesn't exist
        try FileManager.default.createDirectory(at: shootDirectory, withIntermediateDirectories: true)
        
        let fileURL = shootDirectory.appendingPathComponent(fileName)
        
        // Convert UIImage to JPEG data with original quality
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            throw NSError(domain: "DataManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG data"])
        }
        
        // Save image to file
        try imageData.write(to: fileURL)
        
        // Create thumbnail (smaller for UI display only)
        let thumbnailSize = CGSize(width: 300, height: 300)
        let thumbnail = image.resized(to: thumbnailSize)
        let thumbnailData = thumbnail.jpegData(compressionQuality: 0.8)
        
        // Create MediaAsset
        let asset = MediaAsset(
            fileName: fileName,
            fileSize: Int64(imageData.count),
            mediaType: .photo,
            localFilePath: fileURL.path
        )
        
        // Set thumbnail data
        asset.thumbnailData = thumbnailData
        
        // Add the asset to the shoot's mediaAssets array
        shoot.addMediaAsset(asset)
        
        modelContext.insert(asset)
        try modelContext.save()
        
        
        return asset
    }
    
    func createMediaAsset(from videoURL: URL, for shoot: Shoot) async throws -> MediaAsset {
        // Generate a unique filename
        let fileName = "\(UUID().uuidString).mov"
        
        // Get the documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let shootDirectory = documentsPath.appendingPathComponent("Shoots").appendingPathComponent(shoot.id.uuidString)
        
        // Create shoot directory if it doesn't exist
        try FileManager.default.createDirectory(at: shootDirectory, withIntermediateDirectories: true)
        
        let destinationURL = shootDirectory.appendingPathComponent(fileName)
        
        // Copy video file to our directory
        try FileManager.default.copyItem(at: videoURL, to: destinationURL)
        
        // Get file size
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: destinationURL.path)
        let fileSize = fileAttributes[.size] as? Int64 ?? 0
        
        // Create thumbnail from video
        let thumbnail = try await generateVideoThumbnail(from: videoURL)
        let thumbnailData = thumbnail.jpegData(compressionQuality: 0.8)
        
        // Create MediaAsset
        let asset = MediaAsset(
            fileName: fileName,
            fileSize: fileSize,
            mediaType: .video,
            localFilePath: destinationURL.path
        )
        
        // Set thumbnail data
        asset.thumbnailData = thumbnailData
        
        // Add the asset to the shoot's mediaAssets array
        shoot.addMediaAsset(asset)
        
        modelContext.insert(asset)
        try modelContext.save()
        
        
        return asset
    }
    
    private func generateVideoThumbnail(from videoURL: URL) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            let asset = AVAsset(url: videoURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.maximumSize = CGSize(width: 300, height: 300)
            
            let time = CMTime(seconds: 1, preferredTimescale: 60)
            
            imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, image, _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let cgImage = image {
                    let uiImage = UIImage(cgImage: cgImage)
                    continuation.resume(returning: uiImage)
                } else {
                    continuation.resume(throwing: NSError(domain: "DataManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to generate video thumbnail"]))
                }
            }
        }
    }
    
    func fetchMediaAssets(for shoot: Shoot) throws -> [MediaAsset] {
        // Simple fetch all and filter in memory for now
        let allAssets = try modelContext.fetch(FetchDescriptor<MediaAsset>())
        return allAssets.filter { $0.shoot?.id == shoot.id }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    func deleteMediaAsset(_ asset: MediaAsset) throws {
        // Remove file from disk if present
        let path = asset.localFilePath
        if !path.isEmpty {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: url.path) {
                try? FileManager.default.removeItem(at: url)
            }
        }
        
        if let shoot = asset.shoot {
            shoot.removeMediaAsset(asset)
        }
        modelContext.delete(asset)
        try modelContext.save()
    }
    
    func updateMediaAsset(_ asset: MediaAsset) throws {
        try modelContext.save()
    }
    
    // MARK: - Utility Methods
    func getShootCount() throws -> Int {
        let descriptor = FetchDescriptor<Shoot>(
            predicate: #Predicate<Shoot> { $0.isActive == true }
        )
        return try modelContext.fetchCount(descriptor)
    }
    
    func getTotalMediaCount() throws -> Int {
        let descriptor = FetchDescriptor<MediaAsset>()
        return try modelContext.fetchCount(descriptor)
    }
    
    func clearAllData() throws {
        try modelContext.delete(model: Shoot.self)
        try modelContext.delete(model: MediaAsset.self)
        try modelContext.save()
    }
}

// MARK: - UIImage Extension
extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            // Maintain aspect ratio
            let aspectRatio = self.size.width / self.size.height
            let targetAspectRatio = size.width / size.height
            
            var drawRect: CGRect
            if aspectRatio > targetAspectRatio {
                // Image is wider than target
                let newWidth = size.width
                let newHeight = size.width / aspectRatio
                drawRect = CGRect(x: 0, y: (size.height - newHeight) / 2, width: newWidth, height: newHeight)
            } else {
                // Image is taller than target
                let newHeight = size.height
                let newWidth = size.height * aspectRatio
                drawRect = CGRect(x: (size.width - newWidth) / 2, y: 0, width: newWidth, height: newHeight)
            }
            
            self.draw(in: drawRect)
        }
    }
}
