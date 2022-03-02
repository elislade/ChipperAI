import Foundation
import Combine

public protocol Interruptable {
    var isPaused: Bool { get }
    
    func pause()
    func resume()
    func stop()
}


public protocol TranscribableMessage: Equatable {
    associatedtype Content: StringProtocol
    
    var id: UUID { get }
    var content: Content { get }
    var date: Date { get }
}


public protocol Transcribable: Equatable {
    associatedtype Action: Hashable
    associatedtype Message: TranscribableMessage
    
    var id: UUID { get }
    var action: Action { get }
    
    var messages: [Message] { get set }
}


extension Transcribable {
    public var date: Date {
        messages.last?.date ?? Date()
    }
}


public protocol Transcriber: AnyObject {
    associatedtype Item: Transcribable
    var transcript: [Item] { get set }
    
    func transcribe(_ item: Item)
}


extension Transcriber {
    public func transcribe(_ item: Item) {
        if transcript.last?.action == item.action {
            transcript[transcript.count - 1].messages.append(contentsOf: item.messages)
        } else {
            transcript.append(item)
        }
    }
}


public protocol Speakable {
    var isSpeaking: Bool { get }
    
    func speak(_ string: String, done: @escaping () -> Void) -> Void
}


public protocol Listenable {
    var isListening: Bool { get }
    
    func listen(context: Any?, done: @escaping (Result<String, Error>) -> Void)
}


public protocol Askable: Transcriber where Item == AI.TranscriptItem {
    
    associatedtype Ear: Listenable
    associatedtype Voice: Speakable, Interruptable
    
    var ears: Ear { get }
    var voice: Voice  { get }
}


extension Askable {
    
    var isBusy: Bool { isSpeaking || isListening }
    var isSpeaking: Bool { voice.isSpeaking }
    var isListening: Bool { ears.isListening }
    
    public func speak(_ string: String, transcribe: Bool = true, done: @escaping (() -> Void) = {}) {
        voice.speak(string, done: {
            if transcribe {
                self.transcribe(AI.TranscriptItem(.spoke, string))
            }
            done()
        })
    }
    
    public func listen(context: Any? = nil, transcribe: Bool = true, done: @escaping (Result<String, Error>) -> Void) {
        ears.listen(context: context, done: { res in
            if transcribe {
                if let r = try? res.get() {
                    self.transcribe(AI.TranscriptItem(.heard, r))
                }
            }
            done(res)
        })
    }
}


extension Askable {
    public func ask(_ question: String, response: @escaping (String) -> Void) {
        voice.pause()
        
        func done(_ res: Result<String, Error>){
            do {
                let r = try res.get()
                response(r)
                self.voice.resume()
            } catch {
                let ns = error as NSError
                if ns.code == 203 {
                    self.speak("Sorry, I didn't quite catch that!") {
                        self.listen(context: nil, done: done)
                    }
                } else {
                    self.speak(ns.localizedDescription)
                }
            }
        }
        
        speak(question) {
            self.listen(context: nil, done: done)
        }
    }
}
