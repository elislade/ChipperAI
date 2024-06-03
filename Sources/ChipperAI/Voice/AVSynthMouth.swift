import Foundation
import AVFoundation
import Combine

public class AVSynthMouth: NSObject {
    
    private let synth = AVSpeechSynthesizer()
    private let voice: AVSpeechSynthesisVoice
    private var uttering: AVSpeechUtterance?
    public var bufferProvider: (AVAudioPCMBuffer) -> Void = { _ in}
    
    @Published private var saying: String?
    
    public init(voice: AVSpeechSynthesisVoice = AVSpeechSynthesisVoice()) {
        self.voice = voice
        super.init()
        synth.delegate = self
        #if !os(macOS)
        synth.usesApplicationAudioSession = false
        #endif
    }
    
}


extension AVSynthMouth: AVSpeechSynthesizerDelegate {
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        self.saying = nil
        self.uttering = nil
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        self.saying = nil
        self.uttering = nil
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        let str = utterance.speechString
        let end = str.index(str.startIndex, offsetBy: characterRange.upperBound)
        saying = String(str[str.startIndex..<end])
    }
    
}


extension AVSynthMouth: Speakable {
    
    public var isSpeaking: Bool { synth.isSpeaking }
    
    public var sayingPublisher: AnyPublisher<String?, Never> {
        $saying.eraseToAnyPublisher()
    }
    
    public func speak(_ string: String) async {
        saying = nil
        uttering = nil
        
        let utterance = AVSpeechUtterance(string: string)
        utterance.preUtteranceDelay = 0.3
        utterance.voice = voice
        synth.speak(utterance)
        uttering = utterance
        
        while uttering != nil {
            if Task.isCancelled {
                synth.stopSpeaking(at: .immediate)
                saying = nil
                uttering = nil
            }
            continue
        }
        
        return
    }
}


extension AVSynthMouth: Interruptable {
    
    public var isPaused: Bool { synth.isPaused }
    
    public func pause() {
        synth.pauseSpeaking(at: .word)
    }
    
    public func resume() {
        synth.continueSpeaking()
    }
    
    public func stop() {
        synth.stopSpeaking(at: .immediate)
        uttering = nil
    }
    
}
