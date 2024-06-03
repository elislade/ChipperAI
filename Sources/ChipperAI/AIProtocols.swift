import Foundation
import Combine


public protocol Runnable {
    var isRunning: Bool { get }
    
    func start()
    func stop()
}

public protocol Transcriber: AnyObject {
    var transcript: [TranscriptMessage] { get set }
    func transcribe(_ item: TranscriptMessage)
}

extension Transcriber {
    
    public func transcribe(_ item: TranscriptMessage) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.transcript.append(item)
        }
    }
    
    public func delete(_ message: TranscriptMessage) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.transcript.removeAll(where: { $0.id == message.id })
        }
    }
    
}

public protocol Askable: Transcriber {
    
    associatedtype Ear: Listenable
    associatedtype Voice: Speakable
    
    var ears: Ear { get }
    var voice: Voice  { get }
}


extension Askable {
    
    public var isBusy: Bool { isSpeaking || isListening }
    public var isSpeaking: Bool { voice.isSpeaking }
    public var isListening: Bool { ears.isListening }
    
    public func speak(_ string: String, transcribe: Bool = true) async {
        guard !string.isEmpty  else { return }
        await voice.speak(string)
        
        if transcribe {
            self.transcribe(TranscriptMessage(
                ownerID: .speakerOwnerID,
                content: .text(string))
            )
        }
    }
    
    public func listen(transcribe: Bool = true) async throws -> String {
        let res = try await ears.listen()
        
        if transcribe && !res.isEmpty {
            self.transcribe(TranscriptMessage(
                ownerID: .listenerOwnerID,
                content: .text(res))
            )
        }
        
        return res
    }
}


extension Askable {
    public func ask(_ question: String) async throws -> String {
        guard !question.isEmpty else { throw NSError(domain: "Not Found", code: 404) }
        
        if voice.isSpeaking, let interruptableVoice = voice as? Interruptable {
            interruptableVoice.pause()
        }
        
        await speak(question)
        
        do {
            return try await listen()
        } catch {
            let ns = error as NSError
            if ns.code == 203 {
                await speak("Sorry, I didn't quite catch that!")
                return try await listen()
            } else {
                await speak(ns.localizedDescription)
                throw error
            }
        }
    }
}
