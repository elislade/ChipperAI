# ChipperAI

ChipperAI is a audio request and response scripting system built with swift. It's a simple abstraction around speech synthesis, microphone sessions, and speech recognition to establish a faux scripted AI interaction.

It's built on simple protocols which allow different components to be changed without changing the underlying scripted interactions.



To use it, simply provide the ask method a string that you want Chipper to say and a closure that handles a response string of what Chipper heard the user say. 

```
let chipper = AI()
chipper.ask("Hello World?"){ answer in
    // do something with answer
}
```

NOTE: You will need to add privacy messages for `NSSpeechRecognitionUsageDescription` and `NSMicrophoneUsageDescription`.
