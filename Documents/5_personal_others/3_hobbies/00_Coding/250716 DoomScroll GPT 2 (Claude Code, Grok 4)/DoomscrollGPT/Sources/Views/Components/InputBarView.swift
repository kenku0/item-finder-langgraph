import SwiftUI

struct InputBarView: View {
  @State private var inputText = ""
  @State private var isVoiceMode = false
  @State private var isRecording = false
  @StateObject private var voiceService = VoiceService()
  @EnvironmentObject var subscriptionManager: SubscriptionManager
  
  let onSendMessage: (String) -> Void
  
  var body: some View {
    VStack(spacing: 0) {
      if let remainingText = subscriptionManager.getRemainingScrollsText() {
        Text(remainingText)
          .font(.caption)
          .foregroundColor(.white.opacity(0.6))
          .padding(.horizontal)
          .padding(.bottom, 4)
      }
      
      HStack(spacing: 12) {
        HStack {
          TextField("How can Doomscroll GPT help?", text: $inputText)
            .textFieldStyle(PlainTextFieldStyle())
            .foregroundColor(.white)
            .font(.system(size: 16))
            .disabled(isRecording)
            .onSubmit(sendMessage)
          
          Button(action: toggleVoiceMode) {
            Image(systemName: isRecording ? "mic.fill" : "mic")
              .foregroundColor(isRecording ? .red : .white)
              .font(.system(size: 18))
              .scaleEffect(isRecording ? 1.2 : 1.0)
              .animation(.easeInOut(duration: 0.2), value: isRecording)
          }
          .disabled(!voiceService.isAvailable)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
          RoundedRectangle(cornerRadius: 20)
            .fill(Color.white.opacity(0.1))
        )
        .overlay(
          RoundedRectangle(cornerRadius: 20)
            .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        
        if !inputText.isEmpty {
          Button(action: sendMessage) {
            Image(systemName: "arrow.up.circle.fill")
              .foregroundColor(.white)
              .font(.system(size: 28))
          }
          .transition(.scale.combined(with: .opacity))
        }
      }
      .padding(.horizontal)
      .padding(.bottom, 8)
    }
    .background(
      LinearGradient(
        gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.8)]),
        startPoint: .top,
        endPoint: .bottom
      )
    )
    .onReceive(voiceService.$recognizedText) { text in
      if !text.isEmpty {
        inputText = text
      }
    }
    .onReceive(voiceService.$isRecording) { recording in
      isRecording = recording
    }
    .alert("Voice Recognition Error", isPresented: $voiceService.showError) {
      Button("OK") { }
    } message: {
      Text(voiceService.errorMessage)
    }
  }
  
  private func toggleVoiceMode() {
    if isRecording {
      voiceService.stopRecording()
    } else {
      voiceService.startRecording()
    }
  }
  
  private func sendMessage() {
    guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
    
    let message = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
    onSendMessage(message)
    inputText = ""
    
    voiceService.stopRecording()
  }
}

#Preview {
  InputBarView { message in
    print("Sent: \(message)")
  }
  .background(Color.black)
  .environmentObject(SubscriptionManager())
}