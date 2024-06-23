import Foundation

public protocol BufferProvider: AnyObject {
    associatedtype Buffer: Sendable
    var bufferStream: AsyncStream<Buffer> { get }
}

public protocol Listenable {
    
    var textStream: AsyncThrowingStream<String, Error> { get }
    
}

public final class AnyListenable: Listenable {
    
    public var textStream: AsyncThrowingStream<String, Error> { listenable.textStream }
    
    private let erasedValue: Any
    private var listenable: any Listenable { erasedValue as! any Listenable }
    
    public init<Hearing: Listenable>(_ hearing: Hearing){
        self.erasedValue = hearing
    }
    
}
