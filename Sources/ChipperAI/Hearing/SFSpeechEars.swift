import Foundation
import Speech

public final class SFSpeechEars<AudioSource: BufferProvider>: Listenable {
    
    private let audioSource: AudioSource
    private let recognizer: SFSpeechRecognizer
    private let delegateWrapper = SFSpeechRecognitionTaskDelegateWrapper()
    
    private init(audioSource: AudioSource) {
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            fatalError("SFSpeechEars requires SFSpeechRecognizer authorization before initialization.")
        }
        
        guard let recognizer = SFSpeechRecognizer() else {
            fatalError("SFSpeechEars could not initialize SFSpeechRecognizer.")
        }
        
        self.audioSource = audioSource
        self.recognizer = recognizer
    }
    
    public var textStream: AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { [unowned self] continuation in
            let request = SFSpeechAudioBufferRecognitionRequest()
            let task = recognizer.recognitionTask(with: request, delegate: delegateWrapper)
            var timer: Timer?
            
            let bufferTask = Task {
                for await buffer in audioSource.bufferStream {
                    if let buffer = buffer as? AVAudioPCMBuffer {
                        request.append(buffer)
                    } else {
                        request.appendAudioSampleBuffer(buffer as! CMSampleBuffer)
                    }
                }
            }
            
            continuation.onTermination = { type in
                bufferTask.cancel()
                
                switch type {
                case .finished: task.finish()
                case .cancelled: task.cancel()
                @unknown default: task.cancel()
                }
            }

            delegateWrapper.wasCancelled = { task in
                bufferTask.cancel()
                request.endAudio()
            }
            
            delegateWrapper.didHypothesize = { task, transcription in
                timer?.invalidate()
                timer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false){ [task] _ in
                    task.finish()
                }

                continuation.yield(transcription.formattedString)
            }
            
            delegateWrapper.didFinish = { task, recognitionResult in
                bufferTask.cancel()
                request.endAudio()
                continuation.yield(recognitionResult.bestTranscription.formattedString)
                
                if let error = task.error  {
                    continuation.finish(throwing: error)
                } else {
                    continuation.finish()
                }
            }
        }
    }
    
}

extension SFSpeechEars where AudioSource.Buffer == CMSampleBuffer {
    
    public convenience init(sample: AudioSource = AVSessionAudioProvider()){
        self.init(audioSource: sample)
    }
    
}

extension SFSpeechEars where AudioSource.Buffer == AVAudioPCMBuffer {
    
    public convenience init(pcm: AudioSource){
        self.init(audioSource: pcm)
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


