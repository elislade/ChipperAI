import Foundation
import AVFoundation

public final class AVSynthMouth: Speakable {
    
    private let synth = AVSpeechSynthesizer()
    private let voice: AVSpeechSynthesisVoice
    private let delegateWrapper = AVSpeechSynthesizerDelegateWrapper()
    
    public init(voice: AVSpeechSynthesisVoice = AVSpeechSynthesisVoice()) {
        self.voice = voice
        self.synth.delegate = delegateWrapper
        #if !os(macOS)
        self.synth.usesApplicationAudioSession = false
        #endif
    }
    
    public func speak(_ phrase: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream{ [unowned self] continuation in
            continuation.onTermination = { [synth] type in
                switch type {
                case .finished: return
                case .cancelled: synth.stopSpeaking(at: .immediate)
                @unknown default: return
                }
            }
           
            let utterance = AVSpeechUtterance(string: phrase)
            utterance.preUtteranceDelay = 0.3
            utterance.postUtteranceDelay = 0.5
            utterance.voice = voice
            
            synth.speak(utterance)
            
            delegateWrapper.didFinish = { _, _ in
                continuation.finish()
            }
            
            delegateWrapper.willSpeakRangeOfSpeechString = { _, range, utterance in
                let str = utterance.speechString
                let end = str.index(str.startIndex, offsetBy: range.upperBound)
                continuation.yield(String(str[str.startIndex..<end]))
            }
        }
    }
    
}


final class AVSpeechSynthesizerDelegateWrapper: NSObject, AVSpeechSynthesizerDelegate {
    
    var didFinish: (AVSpeechSynthesizer, AVSpeechUtterance) -> Void = { _,_ in }
    var didCancel: (AVSpeechSynthesizer, AVSpeechUtterance) -> Void = { _,_ in }
    var willSpeakRangeOfSpeechString: (AVSpeechSynthesizer, NSRange, AVSpeechUtterance) -> Void = { _,_,_ in }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        didFinish(synthesizer, utterance)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
       didCancel(synthesizer, utterance)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        willSpeakRangeOfSpeechString(synthesizer, characterRange, utterance)
    }
    
}
