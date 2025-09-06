import SwiftUI
import AVFoundation
import SwiftData

struct CameraView: View {
    @ObservedObject private var cameraService = CameraService()
    
    let activeShoot: Shoot
    let dataManager: DataManager
    
    var body: some View {
        ZStack(alignment: .bottom) {
            CameraPreview(session: cameraService.session)
                .ignoresSafeArea()
            
            shutterButton
        }
        .onAppear { cameraService.start() }
        .onDisappear { cameraService.stop() }
    }
    
    private var shutterButton: some View {
        Button(action: capture) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 84, height: 84)
                Circle()
                    .fill(Color.white)
                    .frame(width: 70, height: 70)
                    .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 4)
            }
        }
        .padding(.bottom, 32)
    }
    
    private func capture() {
        cameraService.capturePhoto { data in
            guard let data = data else { return }
            
            // Persist to disk (temporary simple approach)
            let fileName = "IMG_\(Int(Date().timeIntervalSince1970)).jpg"
            let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                .appendingPathComponent("Shoots/\(activeShoot.id.uuidString)", isDirectory: true)
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let fileURL = directory.appendingPathComponent(fileName)
            do {
                try data.write(to: fileURL)
                let fileSize = (try? Data(contentsOf: fileURL).count).map { Int64($0) } ?? 0
                _ = try? dataManager.createMediaAsset(
                    fileName: fileName,
                    fileSize: fileSize,
                    mediaType: .photo,
                    localFilePath: fileURL.path,
                    in: activeShoot
                )
            } catch {
                print("Failed to write photo: \(error)")
            }
        }
    }
}

// MARK: - Live Preview Layer
private struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {}
}

private final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}
