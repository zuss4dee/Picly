import SwiftUI

struct ZoomableImageView: View {
    let image: UIImage
    
    @State private var currentZoom: CGFloat = 1.0
    @State private var lastZoom: CGFloat = 1.0
    
    private let minZoom: CGFloat = 0.5
    private let maxZoom: CGFloat = 5.0
    
    var body: some View {
        GeometryReader { geometry in
            if currentZoom > 1.0 {
                // Only use ScrollView when zoomed in
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                        .scaleEffect(currentZoom)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastZoom
                                    lastZoom = value
                                    let newZoom = currentZoom * delta
                                    currentZoom = min(max(newZoom, minZoom), maxZoom)
                                }
                                .onEnded { _ in
                                    lastZoom = 1.0
                                }
                        )
                }
                .clipped()
            } else {
                // When not zoomed, use a simple image view with only magnification gesture
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                    .scaleEffect(currentZoom)
                    .clipped()
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / lastZoom
                                lastZoom = value
                                let newZoom = currentZoom * delta
                                currentZoom = min(max(newZoom, minZoom), maxZoom)
                            }
                            .onEnded { _ in
                                lastZoom = 1.0
                            }
                    )
            }
        }
        .background(Color.black)
        .clipped()
        .onAppear {
            // Reset zoom when image changes
            currentZoom = 1.0
            lastZoom = 1.0
        }
    }
}

#Preview {
    let sampleImage = UIImage(systemName: "photo") ?? UIImage()
    return ZoomableImageView(image: sampleImage)
}