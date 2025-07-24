import Foundation
import Speech
import AVFoundation

class VoiceService: NSObject, ObservableObject {
  @Published var recognizedText = ""
  @Published var isRecording = false
  @Published var isAvailable = false
  @Published var showError = false
  @Published var errorMessage = ""
  
  private var speechRecognizer: SFSpeechRecognizer?
  private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
  private var recognitionTask: SFSpeechRecognitionTask?
  private let audioEngine = AVAudioEngine()
  
  override init() {
    super.init()
    setupSpeechRecognizer()
    requestPermissions()
  }
  
  private func setupSpeechRecognizer() {
    speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    speechRecognizer?.delegate = self
    
    isAvailable = speechRecognizer?.isAvailable ?? false
  }
  
  private func requestPermissions() {
    SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
      DispatchQueue.main.async {
        switch authStatus {
        case .authorized:
          self?.requestMicrophonePermission()
        case .denied, .restricted, .notDetermined:
          self?.isAvailable = false
          self?.showError(message: "Speech recognition not authorized")
        @unknown default:
          self?.isAvailable = false
        }
      }
    }
  }
  
  private func requestMicrophonePermission() {
    if #available(iOS 17.0, *) {
      AVAudioApplication.requestRecordPermission { [weak self] granted in
        DispatchQueue.main.async {
          if granted {
            self?.isAvailable = true
          } else {
            self?.isAvailable = false
            self?.showError(message: "Microphone access required for voice input")
          }
        }
      }
    } else {
      AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
        DispatchQueue.main.async {
          if granted {
            self?.isAvailable = true
          } else {
            self?.isAvailable = false
            self?.showError(message: "Microphone access required for voice input")
          }
        }
      }
    }
  }
  
  func startRecording() {
    guard isAvailable else {
      showError(message: "Voice recognition not available")
      return
    }
    
    guard !audioEngine.isRunning else { return }
    
    recognitionTask?.cancel()
    recognitionTask = nil
    
    let audioSession = AVAudioSession.sharedInstance()
    
    do {
      try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
      try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    } catch {
      showError(message: "Failed to set up audio session: \(error.localizedDescription)")
      return
    }
    
    recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    
    // Ensure audio engine is properly configured
    guard audioEngine.inputNode.inputFormat(forBus: 0).channelCount > 0 else {
      showError(message: "Audio input not available")
      return
    }
    
    let inputNode = audioEngine.inputNode
    
    guard let recognitionRequest = recognitionRequest else {
      showError(message: "Unable to create recognition request")
      return
    }
    
    recognitionRequest.shouldReportPartialResults = true
    
    if #available(iOS 13, *) {
      recognitionRequest.requiresOnDeviceRecognition = false
    }
    
    recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
      DispatchQueue.main.async {
        if let result = result {
          self?.recognizedText = result.bestTranscription.formattedString
        }
        
        if let error = error {
          self?.showError(message: "Recognition error: \(error.localizedDescription)")
          self?.stopRecording()
        }
      }
    }
    
    let recordingFormat = inputNode.outputFormat(forBus: 0)
    
    // Check if the format is valid
    guard recordingFormat.sampleRate > 0 else {
      showError(message: "Invalid audio format. Please try again.")
      return
    }
    
    inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
      self.recognitionRequest?.append(buffer)
    }
    
    audioEngine.prepare()
    
    do {
      try audioEngine.start()
      isRecording = true
      recognizedText = ""
    } catch {
      showError(message: "Failed to start recording: \(error.localizedDescription)")
    }
  }
  
  func stopRecording() {
    audioEngine.stop()
    audioEngine.inputNode.removeTap(onBus: 0)
    
    recognitionRequest?.endAudio()
    recognitionRequest = nil
    
    recognitionTask?.cancel()
    recognitionTask = nil
    
    isRecording = false
    
    do {
      try AVAudioSession.sharedInstance().setActive(false)
    } catch {
      print("Failed to deactivate audio session: \(error)")
    }
  }
  
  private func showError(message: String) {
    errorMessage = message
    showError = true
    isRecording = false
  }
  
  deinit {
    stopRecording()
  }
}

extension VoiceService: SFSpeechRecognizerDelegate {
  func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
    DispatchQueue.main.async {
      self.isAvailable = available
      if !available && self.isRecording {
        self.stopRecording()
      }
    }
  }
}
