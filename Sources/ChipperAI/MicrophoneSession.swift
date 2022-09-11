import Foundation
import AVFoundation

public class MicrophoneSession: NSObject {
    
    private let playbackQueue = DispatchQueue(label: "mic_playback")
    private let sampleBufferQueue = DispatchQueue(label: "mic_buffer")
    private let captureSession = AVCaptureSession()
    private let audioCapture = AVCaptureAudioDataOutput()
    
    public var didOutputBuffer: (CMSampleBuffer) -> Void
        
    public init(_ didOutputBuffer: @escaping ((CMSampleBuffer) -> Void) = { _ in }) {
        self.didOutputBuffer = didOutputBuffer
        super.init()
        auth()
        audioCapture.setSampleBufferDelegate(self, queue: sampleBufferQueue)
        captureSession.addOutput(audioCapture)
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
    
    private func auth() {
        AVCaptureDevice.requestAccess(for: .audio){ authed in
            if authed {
                self.configureSession()
            } else {
                self.auth()
            }
        }
    }
    
    public func start() {
        playbackQueue.sync {
            self.captureSession.startRunning()
        }
    }
    
    public func stop() {
        playbackQueue.sync {
            self.captureSession.stopRunning()
        }
    }
}

extension MicrophoneSession: AVCaptureAudioDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        didOutputBuffer(sampleBuffer)
    }
}
