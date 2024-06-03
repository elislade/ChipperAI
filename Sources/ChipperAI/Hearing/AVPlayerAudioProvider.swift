import Foundation
import AVFoundation
import Combine

final public class AVPlayerAudioProvider {
    
    private let engine: AVAudioEngine
    private let player: AVAudioPlayerNode
    private let file: AVAudioFile
    private let bufferPasthrough = PassthroughSubject<AVAudioPCMBuffer, Never>()
    
    public init(fileUrl: URL) {
        do {
            self.file = try AVAudioFile(forReading: fileUrl)
            self.engine = AVAudioEngine()
            self.player = AVAudioPlayerNode()
            
            engine.attach(player)
            engine.connect(player, to: engine.outputNode, format: file.processingFormat)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}


extension AVPlayerAudioProvider: BufferProvider {
    
    public var bufferPublisher: AnyPublisher<AVAudioPCMBuffer, Never> {
        bufferPasthrough.eraseToAnyPublisher()
    }
    
}


extension AVPlayerAudioProvider: Runnable {
    
    public var isRunning: Bool { player.isPlaying }
    
    public func start() {
        guard !isRunning else { return }
        
        do {
            try engine.start()
            player.installTap(
                onBus: 0,
                bufferSize: AVAudioFrameCount(file.length),
                format: file.processingFormat
            ){ [weak self] buffer, time in
                self?.bufferPasthrough.send(buffer)
            }
            
            player.scheduleFile(file, at: nil)
            player.play(at: nil)
        } catch {
            print("Start", error)
        }
    }
    
    public func stop() {
        guard isRunning else { return }
        player.stop()
        player.removeTap(onBus: 0)
        engine.stop()
    }

}
