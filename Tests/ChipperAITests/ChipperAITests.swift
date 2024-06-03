import XCTest
import Speech
@testable import ChipperAI

final class ChipperAITests: XCTestCase {
    
    private func authorizeSpeech() async -> Bool {
        await withCheckedContinuation{ continuation in
            SFSpeechRecognizer.requestAuthorization{ staus in
                continuation.resume(returning: staus == .authorized)
            }
        }
    }
    
    func testDuck() async throws {
        let isAuthorized = await authorizeSpeech()
        XCTAssert(isAuthorized)
        
        let url = Bundle.module.url(forResource: "duck", withExtension: "mp3")!
        let audioSource = AVPlayerAudioProvider(fileUrl: url)
        let ears = SFSpeechEars(pcm: audioSource)
        let chipper = AI(ears: ears)
        await chipper.speak("Please say 'Duck'.")
        audioSource.start()
        let res = try! await chipper.listen()
        audioSource.stop()
        XCTAssert(res.lowercased().contains("duck"))
    }
    
}
