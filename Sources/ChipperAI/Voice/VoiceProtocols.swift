import Foundation

public protocol Interruptable {
    var isPaused: Bool { get }
    
    func pause()
    func resume()
    func stop()
}


public protocol Speakable {
    
    func speak(_ phrase: String) -> AsyncThrowingStream<String, Error>
    
}


public final class AnySpeakable: Speakable {
    
    private let erasedValue: Any
    private var speakable: Speakable { erasedValue as! Speakable }
    
    public init<Voice: Speakable>(_ voice: Voice){
        self.erasedValue = voice
    }
    
    public func speak(_ phrase: String) -> AsyncThrowingStream<String, any Error> {
        speakable.speak(phrase)
    }
    
}
