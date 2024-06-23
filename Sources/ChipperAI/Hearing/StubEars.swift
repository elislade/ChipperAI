import Foundation

public final class StubEar : Listenable {
    
    private let cannedResponses: [String]
    private var currentCannedResponseIndex: Int = 0
    
    public init(cannedResponses: [String]) {
        self.cannedResponses = cannedResponses
    }
    
    public var textStream: AsyncThrowingStream<String, any Error> {
        AsyncThrowingStream{ continuation in
            
            let task = Task { [unowned self] in
                let response = cannedResponses[currentCannedResponseIndex]
                var length = 1
                
                usleep(1_000_000)
                
                while length <= response.count {
                    usleep(.random(in: 40_000...70_000))

                    let stringIndex = response.index(response.startIndex, offsetBy: length)
                    continuation.yield(String(response[..<stringIndex]))
                    
                    length += 1
                }
                
                usleep(400_000)
                
                if currentCannedResponseIndex == (cannedResponses.count - 1) {
                    currentCannedResponseIndex = 0
                } else {
                    currentCannedResponseIndex += 1
                }
                
                continuation.finish()
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
}
