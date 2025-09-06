import SwiftUI
import UIKit
import AVFoundation

struct SystemCameraView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIImagePickerController
    
    let activeShoot: Shoot
    let dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.cameraDevice = .rear
        picker.showsCameraControls = true // Use the built-in camera UI and settings
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(activeShoot: activeShoot, dataManager: dataManager, dismiss: dismiss)
    }
    
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let activeShoot: Shoot
        let dataManager: DataManager
        let dismiss: DismissAction
        
        init(activeShoot: Shoot, dataManager: DataManager, dismiss: DismissAction) {
            self.activeShoot = activeShoot
            self.dataManager = dataManager
            self.dismiss = dismiss
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage, let data = image.jpegData(compressionQuality: 0.95) {
                save(data: data)
            }
            dismiss()
        }
        
        private func save(data: Data) {
            let fileName = "IMG_\(Int(Date().timeIntervalSince1970)).jpg"
            let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                .appendingPathComponent("Shoots/\(activeShoot.id.uuidString)", isDirectory: true)
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let fileURL = directory.appendingPathComponent(fileName)
            do {
                try data.write(to: fileURL)
                let fileSize = Int64(data.count)
                _ = try? dataManager.createMediaAsset(
                    fileName: fileName,
                    fileSize: fileSize,
                    mediaType: .photo,
                    localFilePath: fileURL.path,
                    in: activeShoot
                )
            } catch {
                print("Failed to write system camera photo: \(error)")
            }
        }
    }
}

#Preview {
    Text("System Camera")
}
