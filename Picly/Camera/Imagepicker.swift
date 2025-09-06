import SwiftUI
import UIKit
import UniformTypeIdentifiers

// MARK: - Media Result Enum
enum MediaResult {
    case image(UIImage)
    case video(URL)
}

struct ImagePicker: UIViewControllerRepresentable {
    let onMediaPicked: (MediaResult) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onMediaPicked: onMediaPicked)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.delegate = context.coordinator
        controller.sourceType = .camera
        controller.mediaTypes = [UTType.image.identifier, UTType.movie.identifier]
        controller.allowsEditing = false
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onMediaPicked: (MediaResult) -> Void
        
        init(onMediaPicked: @escaping (MediaResult) -> Void) {
            self.onMediaPicked = onMediaPicked
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // Handle image
            if let image = info[.originalImage] as? UIImage {
                onMediaPicked(.image(image))
            }
            // Handle video
            else if let videoURL = info[.mediaURL] as? URL {
                onMediaPicked(.video(videoURL))
            }
            
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}