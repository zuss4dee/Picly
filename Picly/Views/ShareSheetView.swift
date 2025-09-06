import SwiftUI

struct ShareSheetView: View {
    let images: [UIImage]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if images.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No images to share")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("This project doesn't contain any images")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    Text("Ready to share \(images.count) image\(images.count == 1 ? "" : "s")")
                        .font(.headline)
                        .padding()
                    
                    Button(action: {
                        let activityViewController = UIActivityViewController(activityItems: images, applicationActivities: nil)
                        
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            window.rootViewController?.present(activityViewController, animated: true)
                        }
                    }) {
                        Label("Share Images", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Share Images")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ShareSheetView(images: [])
}
