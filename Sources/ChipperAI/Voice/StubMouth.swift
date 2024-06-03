import Foundation
import Combine

public final class StubMouth {
    
    @Published private var speaking: String?
    
    private var active = false
    private var paused = false
    
    public init(){}
    
}

extension StubMouth: Speakable {
    
    public var isSpeaking: Bool { active }
    
    public var sayingPublisher: AnyPublisher<String?, Never> {
        $speaking.eraseToAnyPublisher()
    }
    
    public func speak(_ string: String) async {
        active = true

        var length = 1
        speaking = ""
        
        usleep(1_000_000)
        
        while length <= string.count && active {
            usleep(.random(in: 40_000...70_000))
            
            while paused {
                continue
            }
            
            if Task.isCancelled {
                speaking = nil
                active = false
                return
            }
            
            let stringIndex = string.index(string.startIndex, offsetBy: length)
            speaking = String(string[..<stringIndex])
            
            length += 1
        }
        
        usleep(400_000)
        
        speaking = nil
        active = false
        
        return
    }
    
}


extension StubMouth: Interruptable {
    
    public var isPaused: Bool { paused }
    
    public func pause() {
        guard active else { return }
        paused = true
    }
    
    public func resume() {
        paused = false
    }
    
    public func stop() {
        guard active else { return }
        paused = false
        active = false
    }
    
}
