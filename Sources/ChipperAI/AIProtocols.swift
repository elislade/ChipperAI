import Foundation
import Combine

public protocol Interruptable {
    var isPaused: Bool { get }
    
    func pause()
    func resume()
    func stop()
}


public protocol Transcriber: AnyObject {
    var transcript: [TranscriptItem] { get set }
    func transcribe(_ item: TranscriptItem)
}

extension Transcriber {
    public func transcribe(_ item: TranscriptItem) {
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
    
    func listen(done: @escaping (Result<String, Error>) -> Void)
}


public protocol Askable: Transcriber {
    
    associatedtype Ear: Listenable
    associatedtype Voice: Speakable, Interruptable
    
    var ears: Ear { get }
    var voice: Voice  { get }
}


extension Askable {
    
    public var isBusy: Bool { isSpeaking || isListening }
    public var isSpeaking: Bool { voice.isSpeaking }
    public var isListening: Bool { ears.isListening }
    
    public func speak(_ string: String, transcribe: Bool = true, done: @escaping (() -> Void) = {}) {
        voice.speak(string, done: {
            if transcribe {
                self.transcribe(TranscriptItem(.spoke, string))
            }
            done()
        })
    }
    
    public func listen(transcribe: Bool = true, done: @escaping (Result<String, Error>) -> Void) {
        ears.listen(done: { res in
            if transcribe {
                if let r = try? res.get() {
                    self.transcribe(TranscriptItem(.heard, r))
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
                        self.listen(done: done)
                    }
                } else {
                    self.speak(ns.localizedDescription)
                }
            }
        }
        
        speak(question) {
            self.listen(done: done)
        }
    }
}
