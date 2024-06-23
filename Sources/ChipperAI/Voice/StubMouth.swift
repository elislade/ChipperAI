import Foundation

public final class StubMouth: Speakable {
    
    public init(){}
    
    public func speak(_ phrase: String) -> AsyncThrowingStream<String, any Error> {
        AsyncThrowingStream{ continuation in
            let task = Task.detached {
                var length = 1
                usleep(1_000_000)
                
                while length <= phrase.count {
                    usleep(.random(in: 40_000...70_000))
                    
                    let stringIndex = phrase.index(phrase.startIndex, offsetBy: length)
                    continuation.yield(String(phrase[..<stringIndex]))
                    
                    length += 1
                }
                
                usleep(400_000)
                continuation.finish()
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
}
