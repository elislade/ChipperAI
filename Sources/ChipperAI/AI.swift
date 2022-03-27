import Foundation
import Combine

public class AI: Askable, ObservableObject {

    public let voice = Mouth()
    public let ears = Ears()
    
    private var bag: Set<AnyCancellable> = []
    
    public init() {
        ears.objectWillChange.sink{ [weak self] in
            self?.objectWillChange.send()
        }.store(in: &bag)
        
        voice.objectWillChange.sink{ [weak self] in
            self?.objectWillChange.send()
        }.store(in: &bag)
    }
    
    public var transcript: [TranscriptItem] = [] {
        willSet { objectWillChange.send() }
    }
}


public struct TranscriptItem: Identifiable {
    
    public enum Action: String, Hashable {
        case heard, spoke
    }
    
    public let id = UUID()
    public let action: Action
    public var messages: [Message]
    
    public var date: Date {
        messages.last?.date ?? Date()
    }
    
    public init(_ action: Action, _ message: String){
        self.action = action
        self.messages = [Message(message)]
    }
    
    public struct Message: Identifiable {
        
        public let id = UUID()
        public var content: String
        public let date = Date()
        
        public init(_ content: String){
            self.content = content
        }
    }
}
