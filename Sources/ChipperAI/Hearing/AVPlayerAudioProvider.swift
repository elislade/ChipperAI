import Foundation
import AVFoundation

public final class AVPlayerAudioProvider: BufferProvider {
    
    private let engine: AVAudioEngine
    private let player: AVAudioPlayerNode
    private let file: AVAudioFile
   
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
    
    public var bufferStream: AsyncStream<AVAudioPCMBuffer> {
        AsyncStream { [unowned self] continuation in
            try? engine.start()
            
            continuation.onTermination = { _ in
                player.stop()
                engine.stop()
            }
            
            player.installTap(
                onBus: 0,
                bufferSize: AVAudioFrameCount(file.length),
                format: file.processingFormat
            ){ [weak self] buffer, time in
                continuation.yield(buffer)
            }
            
            player.scheduleFile(file, at: nil)
            player.play(at: nil)
        }
    }
    
}
