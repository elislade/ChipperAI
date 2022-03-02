import Foundation
import Speech
import Combine

class Ears: NSObject, ObservableObject {
    
    private var request = SFSpeechAudioBufferRecognitionRequest()
    private let microphone = MicrophoneSession()
    private var recognize: SFSpeechRecognizer?
    private var task: SFSpeechRecognitionTask?
    private var active = false
    private var timer: Timer?
    private var completion: (Result<String, Error>) -> Void = { _ in }
    
    @Published private(set) var hearing: String = ""
    
    func authorize() {
        SFSpeechRecognizer.requestAuthorization({ auth in
            if auth == .authorized {
                self.recognize = SFSpeechRecognizer()
            }
        })
    }
    
    override init(){
        super.init()
        authorize()
        microphone.didOutputBuffer = request.appendAudioSampleBuffer
        //request.shouldReportPartialResults = false
        request.taskHint = .dictation
    }
}


extension Ears: SFSpeechRecognitionTaskDelegate {
    
    func speechRecognitionTaskWasCancelled(_ task: SFSpeechRecognitionTask) {
        print("task was cancelled")
    }
    
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didHypothesizeTranscription transcription: SFTranscription) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false, block: { t in
            task.finish()
        })
        
        objectWillChange.send()
        hearing = transcription.formattedString
    }
    
    func speechRecognitionDidDetectSpeech(_ task: SFSpeechRecognitionTask) {
        print("did detect speach")
    }
    
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool) {
        print("finished success", successfully)
    }
    
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishRecognition recognitionResult: SFSpeechRecognitionResult) {
        print("finished recog")
        objectWillChange.send()
        completion(.success(recognitionResult.bestTranscription.formattedString))
        active = false
        hearing = ""
        microphone.stop()
        request.endAudio()
    }
}


extension Ears: Listenable {
    
    var isListening: Bool { active }
    
    func listen(context: Any? = nil, done: @escaping (Result<String, Error>) -> Void){
        microphone.start()
        active = true
        completion = done
        task = recognize?.recognitionTask(with: request, delegate: self)
    }
}
