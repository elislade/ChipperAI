import Foundation
import Speech
import Combine

public final class SFSpeechEars<AudioSource: BufferProvider> {
    
    private let audioSource: AudioSource
    private let delegateWrapper = SFSpeechRecognitionTaskDelegateWrapper()
    private let recognizer: SFSpeechRecognizer
    
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var timer: Timer?
    private var heard: String = ""
    
    private var bag: Set<AnyCancellable> = []
    
    @Published private var hearing: String?
    
    private init(audioSource: AudioSource){
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            fatalError("SFSpeechEars requires SFSpeechRecognizer authorization before initialization.")
        }
        
        guard let recognizer = SFSpeechRecognizer() else {
            fatalError("SFSpeechEars could not initialize SFSpeechRecognizer.")
        }
        
        self.audioSource = audioSource
        self.recognizer = recognizer
        setupDelegateWrapper()
    }
    
    private func setupDelegateWrapper() {
        delegateWrapper.wasCancelled = { [unowned self] task in
            self.cancel()
        }
        
        delegateWrapper.didHypothesize = { [unowned self] task, transcription in
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false){ [task] _ in
                task.finish()
            }
            
            hearing = transcription.formattedString
        }
        
        delegateWrapper.didFinish = { [unowned self] task, recognitionResult in
            hearing = recognitionResult.bestTranscription.formattedString
            heard = recognitionResult.bestTranscription.formattedString
            if let runner = audioSource as? Runnable {
                runner.stop()
            }
            request?.endAudio()
        }
    }
    
}

extension SFSpeechEars where AudioSource.Buffer == CMSampleBuffer {
    public convenience init(sample: AudioSource = AVSessionAudioProvider()){
        self.init(audioSource: sample)
        sample.bufferPublisher.sink{ [weak self] buffer in
            guard let request = self?.request else { return }
            request.appendAudioSampleBuffer(buffer)
        }.store(in: &bag)
    }
}

extension SFSpeechEars where AudioSource.Buffer == AVAudioPCMBuffer {
    public convenience init(pcm: AudioSource){
        self.init(audioSource: pcm)
        pcm.bufferPublisher.sink{ [weak self] buffer in
            guard let request = self?.request else { return }
            request.append(buffer)
        }.store(in: &bag)
    }
}

extension SFSpeechEars: Listenable {
    
    public var isListening: Bool {
        guard let task else { return false }
        return task.state == .running
    }
    
    public var hearingPublisher: AnyPublisher<String?, Never> {
        $hearing.eraseToAnyPublisher()
    }
    
    public func listen() async throws -> String {
        defer {
            hearing = nil
        }
        
        task?.finish()
        task = nil
        heard = ""
        hearing = ""
        
        if let runner = audioSource as? Runnable {
            runner.start()
        }
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        self.request = request
        task = recognizer.recognitionTask(with: request, delegate: delegateWrapper)
        
        while heard.isEmpty {
            if Task.isCancelled {
                cancel()
                return ""
            }
            continue
        }

        task = nil
        self.request?.endAudio()
        self.request = nil
        return heard
    }
}

extension SFSpeechEars: Cancellable {
    
    public func cancel() {
        task?.cancel()
        if let runner = audioSource as? Runnable {
            runner.stop()
        }
        request?.endAudio()
        request = nil
        hearing = nil
        heard = "{{null}}"
    }
    
}


final class SFSpeechRecognitionTaskDelegateWrapper: NSObject, SFSpeechRecognitionTaskDelegate {
    
    var wasCancelled: ((SFSpeechRecognitionTask) -> Void)?
    var didHypothesize: ((SFSpeechRecognitionTask, SFTranscription) -> Void)?
    var didDetectSpeech: ((SFSpeechRecognitionTask) -> Void)?
    var didFinish: ((SFSpeechRecognitionTask, SFSpeechRecognitionResult) -> Void)?
    
    func speechRecognitionTaskWasCancelled(_ task: SFSpeechRecognitionTask) {
        wasCancelled?(task)
    }
    
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didHypothesizeTranscription transcription: SFTranscription) {
        didHypothesize?(task, transcription)
    }
    
    func speechRecognitionDidDetectSpeech(_ task: SFSpeechRecognitionTask) {
        didDetectSpeech?(task)
    }
    
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishRecognition recognitionResult: SFSpeechRecognitionResult) {
        didFinish?(task, recognitionResult)
    }
    
}


public extension SFSpeechRecognizer {
    
    static func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation{ continuation in
            requestAuthorization{ status in
                continuation.resume(returning: status)
            }
        }
    }
    
}
