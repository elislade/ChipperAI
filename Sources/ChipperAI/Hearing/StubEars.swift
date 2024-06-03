import Foundation
import Combine

public final class StubEar {
    
    @Published private var hearing: String?
    
    private let cannedResponses: [String]
    private var currentCannedResponseIndex: Int = 0
    private var active: Bool = false
    
    public init(cannedResponses: [String]) {
        self.cannedResponses = cannedResponses
    }
    
}

extension StubEar: Listenable {
    
    public var isListening: Bool { active }
    
    public var hearingPublisher: AnyPublisher<String?, Never> {
        $hearing.eraseToAnyPublisher()
    }
    
    public func listen() async throws -> String {
        active = true
        
        let response = cannedResponses[currentCannedResponseIndex]
        var length = 1
        hearing = ""
        
        usleep(1_000_000)
        
        while length <= response.count && active {
            usleep(.random(in: 40_000...70_000))
            
            if Task.isCancelled {
                hearing = nil
                active = false
                return response
            }
            
            let stringIndex = response.index(response.startIndex, offsetBy: length)
            hearing = String(response[..<stringIndex])
            
            length += 1
        }
        
        usleep(400_000)
        
        hearing = nil
        active = false
        
        if currentCannedResponseIndex == (cannedResponses.count - 1) {
            currentCannedResponseIndex = 0
        } else {
            currentCannedResponseIndex += 1
        }
        
        return response
    }
    
}


extension StubEar: Cancellable {
    
    public func cancel() {
        hearing = nil
        active = false
    }
    
}
