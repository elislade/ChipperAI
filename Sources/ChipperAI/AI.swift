import Foundation

@MainActor public final class AI: ObservableObject {

    private let voice: AnySpeakable
    private let ears: AnyListenable
    
    @Published public private(set) var error: Error?
    @Published public private(set) var transcript: [TranscriptMessage] = []
    @Published public private(set) var hearing: String? = nil
    @Published public private(set) var saying: String? = nil
    
    public init<Ear: Listenable, Voice: Speakable>(
        ears: Ear = SFSpeechEars(),
        voice: Voice = AVSynthMouth()
    ) {
        self.ears = AnyListenable(ears)
        self.voice = AnySpeakable(voice)
    }
    
    @MainActor public func speak(_ phrase: String) async throws {
        saying = ""
        
        do {
            for try await phrase in voice.speak(phrase) {
                saying = phrase
            }
        } catch {
            self.error = error
            throw error
        }

        if let saying {
            transcript.append(.init(ownerID: .speakerOwnerID, content: .text(saying)))
            self.saying = nil
        }
    }
    
    @MainActor public func listen() async throws -> String {
        hearing = ""
        
        do {
            for try await phrase in ears.textStream {
                hearing = phrase
            }
        } catch {
            self.error = error
            throw error
        }
        
        if let hearing {
            transcript.append(.init(ownerID: .listenerOwnerID, content: .text(hearing)))
            self.hearing = nil
            return hearing
        } else {
            return ""
        }
    }
    
    @MainActor public func ask(_ question: String) async throws -> String {
        guard !question.isEmpty else { throw NSError(domain: "Not Found", code: 404) }
        
        try await speak(question)
        
        do {
            return try await listen()
        } catch {
            let ns = error as NSError
            if ns.code == 203 {
                try await speak("Sorry, I didn't quite catch that!")
                return try await listen()
            } else {
                try await speak(ns.localizedDescription)
                throw error
            }
        }
    }
    
    @MainActor public func delete(_ message: TranscriptMessage) {
         transcript.removeAll(where: { $0.id == message.id })
    }
    
    @MainActor public func clear() {
        hearing = nil
        saying = nil
        transcript = []
    }
    
}


public extension AI {
    
    static func stub(responses: [String] = []) -> AI {
        AI(ears: StubEar(cannedResponses: responses), voice: StubMouth())
    }
    
}
