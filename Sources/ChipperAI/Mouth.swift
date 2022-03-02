import Foundation
import AVFoundation

public class Mouth: NSObject, ObservableObject {
    
    private let synth = AVSpeechSynthesizer()
    private var voice: AVSpeechSynthesisVoice?
    private var queue: [(AVSpeechUtterance, () -> Void)] = []
    
    @Published private(set) var saying = ""
    
    public override init() {
        let choices = AVSpeechSynthesisVoice.speechVoices()
        voice = choices.sorted{ $0.quality.rawValue > $1.quality.rawValue }.first
        super.init()
        synth.delegate = self
    }
}

extension Mouth: AVSpeechSynthesizerDelegate {
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if let i = self.queue.firstIndex(where: { $0.0.speechString == utterance.speechString }){
            self.objectWillChange.send()
            self.saying = ""
            self.queue[i].1()
            self.queue.remove(at: i)
        }
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        let str = utterance.speechString
        let end = str.index(str.startIndex, offsetBy: characterRange.upperBound)
        saying = String(str[str.startIndex..<end])
    }
}

extension Mouth: Speakable {
    public var isSpeaking: Bool { synth.isSpeaking }
    
    public func speak(_ string: String, done: @escaping () -> Void) {
        objectWillChange.send()
        let u = AVSpeechUtterance(string: string)
        u.preUtteranceDelay = 0.3
        u.voice = voice
        queue.append((u, done))
        synth.speak(u)
    }
}

extension Mouth: Interruptable {
    public var isPaused: Bool { synth.isPaused }
    
    public func pause() {
        objectWillChange.send()
        synth.pauseSpeaking(at: .word)
    }
    
    public func resume() {
        objectWillChange.send()
        synth.continueSpeaking()
    }
    
    public func stop() {
        objectWillChange.send()
        synth.stopSpeaking(at: .immediate)
    }
}
