import Foundation
import AVFoundation

public final class AVSessionAudioProvider: BufferProvider {
    
    private let sampleBufferQueue = DispatchQueue(label: "mic_buffer_queue")
    private let captureSession = AVCaptureSession()
    private let audioCapture = AVCaptureAudioDataOutput()
    private let delegateWrapper = AVCaptureAudioDataOutputSampleBufferDelegateWrapper()
    
    public init() {
        guard AVCaptureDevice.authorizationStatus(for: .audio) == .authorized else {
            fatalError("AVSessionAudioProvider requires microphone authorization before initalization.")
        }
        
        audioCapture.setSampleBufferDelegate(delegateWrapper, queue: sampleBufferQueue)
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
        else {
            fatalError("Could not locate microphone capture device.")
        }
        
        captureSession.beginConfiguration()
        captureSession.addInput(input)
        captureSession.commitConfiguration()
    }
    
    
    public var bufferStream: AsyncStream<CMSampleBuffer> {
        AsyncStream { [unowned self] continuation in
            delegateWrapper.didOutput = { _, sample, _ in
                continuation.yield(sample)
            }
            
            captureSession.startRunning()
            
            continuation.onTermination = { [captureSession] _ in
                captureSession.stopRunning()
            }
        }
    }
    
}


final class AVCaptureAudioDataOutputSampleBufferDelegateWrapper: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    var didOutput: (AVCaptureOutput, CMSampleBuffer, AVCaptureConnection) -> Void = { _,_,_ in }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        didOutput(output, sampleBuffer, connection)
    }
    
}
