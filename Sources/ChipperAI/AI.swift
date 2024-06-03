import Foundation
import Combine

public final class AI: Askable, ObservableObject {

    public let voice: AnySpeakable
    public let ears: AnyListenable
    
    @Published public var transcript: [TranscriptMessage] = []
    @Published public private(set) var hearing: String? = nil
    @Published public private(set) var saying: String? = nil
    
    private var bag: Set<AnyCancellable> = []
    
    public init<Ear: Listenable, Voice: Speakable>(
        ears: Ear = SFSpeechEars(),
        voice: Voice = AVSynthMouth()
    ) {
        self.ears = AnyListenable(ears)
        self.voice = AnySpeakable(voice)
        
        ears.hearingPublisher
            .receive(on: DispatchQueue.main)
            .sink{ [weak self] str in
                self?.hearing = str
            }.store(in: &bag)
        
        voice.sayingPublisher
            .receive(on: DispatchQueue.main)
            .sink{ [weak self] str in
                self?.saying = str
            }.store(in: &bag)
    }
    
    public func clear() {
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
