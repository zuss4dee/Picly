import Foundation
import AVFoundation
import UIKit

final class CameraService: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var photoOutput = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    
    @Published var isSessionRunning = false
    
    override init() {
        super.init()
        configureSession()
    }
    
    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        // Input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Failed to get back camera")
            session.commitConfiguration()
            return
        }
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(input) {
                session.addInput(input)
                videoDeviceInput = input
            }
        } catch {
            print("Error creating device input: \(error)")
            session.commitConfiguration()
            return
        }
        
        // Output
        if #available(iOS 16.0, *) {
            // Prefer highest quality the device supports
            if let maxSupported = photoOutput.availablePhotoCodecTypes.first { _ = maxSupported }
            photoOutput.maxPhotoDimensions = .init(width: 9999, height: 9999)
        } else {
            photoOutput.isHighResolutionCaptureEnabled = true
        }
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        
        session.commitConfiguration()
    }
    
    func start() {
        sessionQueue.async {
            guard !self.session.isRunning else { return }
            self.session.startRunning()
            DispatchQueue.main.async { self.isSessionRunning = true }
        }
    }
    
    func stop() {
        sessionQueue.async {
            guard self.session.isRunning else { return }
            self.session.stopRunning()
            DispatchQueue.main.async { self.isSessionRunning = false }
        }
    }
    
    func capturePhoto(completion: @escaping (Data?) -> Void) {
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        if #available(iOS 16.0, *) {
            settings.maxPhotoDimensions = .init(width: 9999, height: 9999)
        } else {
            settings.isHighResolutionPhotoEnabled = true
        }
        photoOutput.capturePhoto(with: settings, delegate: PhotoCaptureProcessor(completion: completion))
    }
}

private final class PhotoCaptureProcessor: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (Data?) -> Void
    
    init(completion: @escaping (Data?) -> Void) {
        self.completion = completion
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Photo capture error: \(error)")
            completion(nil)
            return
        }
        let data = photo.fileDataRepresentation()
        completion(data)
    }
}
