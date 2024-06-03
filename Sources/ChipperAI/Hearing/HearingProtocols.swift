import Foundation
import Combine

public protocol BufferProvider: AnyObject {
    associatedtype Buffer
    var bufferPublisher: AnyPublisher<Buffer, Never> { get }
}

public protocol Listenable {
    var isListening: Bool { get }
    var hearingPublisher: AnyPublisher<String?, Never> { get }
    
    func listen() async throws -> String
}

public final class AnyListenable: Listenable {
    
    public var isListening: Bool { listenable.isListening }
    
    public var hearingPublisher: AnyPublisher<String?, Never> {
        listenable.hearingPublisher
    }
    
    private let erasedValue: Any
    private var listenable: Listenable { erasedValue as! Listenable }
    
    public init<Hearing: Listenable>(_ hearing: Hearing){
        self.erasedValue = hearing
    }
    
    public func listen() async throws -> String {
        try await listenable.listen()
    }
}
