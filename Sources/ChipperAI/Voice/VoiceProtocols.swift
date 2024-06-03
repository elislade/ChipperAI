import Foundation
import Combine

public protocol Interruptable {
    var isPaused: Bool { get }
    
    func pause()
    func resume()
    func stop()
}


public protocol Speakable {
    var isSpeaking: Bool { get }
    var sayingPublisher: AnyPublisher<String?, Never> { get }
    
    func speak(_ string: String) async
}


public final class AnySpeakable: Speakable {
    
    public var isSpeaking: Bool { speakable.isSpeaking }
    
    public var sayingPublisher: AnyPublisher<String?, Never> {
        speakable.sayingPublisher
    }
    
    private let erasedValue: Any
    private var speakable: Speakable { erasedValue as! Speakable }
    
    public init<Voice: Speakable>(_ voice: Voice){
        self.erasedValue = voice
    }
    
    public func speak(_ string: String) async {
        await speakable.speak(string)
    }
}


extension AnySpeakable: Interruptable {
    
    private var interruptable: Interruptable { erasedValue as! Interruptable }
    public var isPaused: Bool { interruptable.isPaused }
    
    public convenience init<Voice: Speakable & Interruptable>(interruptableVoice: Voice){
        self.init(interruptableVoice)
    }
    
    public func pause() {
        interruptable.pause()
    }
    public func resume() { interruptable.resume() }
    public func stop() { interruptable.stop() }
    
}
