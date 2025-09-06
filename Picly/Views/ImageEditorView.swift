import SwiftUI
import UIKit

struct ImageEditorView: UIViewControllerRepresentable {
    let image: UIImage
    let onImageEdited: (UIImage) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImageEdited: onImageEdited)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.delegate = context.coordinator
        controller.sourceType = .photoLibrary
        controller.allowsEditing = true
        controller.modalPresentationStyle = .fullScreen
        
        // Set the image to edit
        context.coordinator.originalImage = image
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImageEdited: (UIImage) -> Void
        var originalImage: UIImage?
        
        init(onImageEdited: @escaping (UIImage) -> Void) {
            self.onImageEdited = onImageEdited
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                onImageEdited(editedImage)
            } else if let originalImage = info[.originalImage] as? UIImage {
                onImageEdited(originalImage)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
