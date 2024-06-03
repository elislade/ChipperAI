import Foundation
import Combine
import AVFoundation

public class AVSessionAudioProvider: NSObject {
    
    private let sampleBufferQueue = DispatchQueue(label: "mic_buffer_queue")
    private let captureSession = AVCaptureSession()
    private let audioCapture = AVCaptureAudioDataOutput()
    private let bufferPassthrough = PassthroughSubject<CMSampleBuffer, Never>()
    
    public override init() {
        guard AVCaptureDevice.authorizationStatus(for: .audio) == .authorized else {
            fatalError("AVSessionAudioProvider requires microphone authorization before initalization.")
        }
        
        super.init()
        audioCapture.setSampleBufferDelegate(self, queue: sampleBufferQueue)
        captureSession.addOutput(audioCapture)
        configureSession()
    }
    
    private func configureSession() {
        let session = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInMicrophone],
            mediaType: .audio,
            position: .unspecified
        )
        
        guard
            let device = session.devices.first,
            let input = try? AVCaptureDeviceInput(device: device)
        else { return }
        
        captureSession.beginConfiguration()
        captureSession.addInput(input)
        captureSession.commitConfiguration()
    }
    
}


extension AVSessionAudioProvider: AVCaptureAudioDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        bufferPassthrough.send(sampleBuffer)
    }
}


extension AVSessionAudioProvider: BufferProvider {
    
    public var bufferPublisher: AnyPublisher<CMSampleBuffer, Never> {
        bufferPassthrough.eraseToAnyPublisher()
    }
    
}


extension AVSessionAudioProvider: Runnable {
    
    public var isRunning: Bool { captureSession.isRunning }
    
    public func start() {
        Task { [weak self] in
            self?.captureSession.startRunning()
        }
    }
    
    public func stop() {
        Task { [weak self] in
            self?.captureSession.stopRunning()
        }
    }
    
}
