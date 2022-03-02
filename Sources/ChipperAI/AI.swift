import Foundation
import Combine

class AI: Askable, ObservableObject {

    let voice = Mouth()
    let ears = Ears()
    
    private var watch: Set<AnyCancellable> = []
    
    init() {
        ears.objectWillChange.sink{
            self.objectWillChange.send()
        }.store(in: &watch)
        
        voice.objectWillChange.sink{
            self.objectWillChange.send()
        }.store(in: &watch)
    }
    
    var transcript: [TranscriptItem] = [] {
        willSet { objectWillChange.send() }
    }
    
    struct TranscriptItem: Transcribable, Identifiable {
        
        enum Action: String, Hashable {
            case heard, spoke
        }
        
        let id = UUID()
        let action: Action
        var messages: [Message]
        
        init(_ action: Action, _ message: String){
            self.action = action
            self.messages = [Message(message)]
        }
        
        struct Message: TranscribableMessage, Identifiable {
            
            let id = UUID()
            var content: String
            let date = Date()
            
            init(_ content: String){
                self.content = content
            }
        }
    }
}
