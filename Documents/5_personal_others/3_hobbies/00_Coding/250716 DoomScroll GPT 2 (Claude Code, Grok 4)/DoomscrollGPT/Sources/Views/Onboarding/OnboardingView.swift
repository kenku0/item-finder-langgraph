import SwiftUI

struct OnboardingView: View {
  @ObservedObject var appState: AppState
  @State private var currentStep = 0
  
  private let steps = [
    OnboardingStep(
      title: "Welcome to Doomscroll GPT",
      description: "Type or speak to start a conversation.",
      instruction: "Engage with Gemini through endless dialogue",
      icon: "text.bubble"
    ),
    OnboardingStep(
      title: "Endless Flow",
      description: "Flick or scroll down to continue the thought. There is no end.",
      instruction: "Let the conversation flow infinitely",
      icon: "arrow.down.circle"
    )
  ]
  
  var body: some View {
    ZStack {
      Color.black
        .ignoresSafeArea()
      
      VStack(spacing: 40) {
        Spacer()
        
        VStack(spacing: 24) {
          Image(systemName: steps[currentStep].icon)
            .font(.system(size: 60))
            .foregroundColor(.white)
            .scaleEffect(1.0)
            .animation(.easeInOut(duration: 0.5), value: currentStep)
          
          Text(steps[currentStep].title)
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
          
          Text(steps[currentStep].description)
            .font(.title3)
            .foregroundColor(.white.opacity(0.8))
            .multilineTextAlignment(.center)
            .padding(.horizontal)
          
          Text(steps[currentStep].instruction)
            .font(.body)
            .foregroundColor(.white.opacity(0.6))
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        }
        
        Spacer()
        
        VStack(spacing: 16) {
          HStack {
            ForEach(0..<steps.count, id: \.self) { index in
              Circle()
                .fill(index <= currentStep ? Color.white : Color.white.opacity(0.3))
                .frame(width: 8, height: 8)
            }
          }
          .padding(.bottom, 16)
          
          HStack(spacing: 16) {
            if currentStep > 0 {
              Button(action: previousStep) {
                Text("Back")
                  .font(.headline)
                  .foregroundColor(.white)
                  .frame(maxWidth: .infinity)
                  .padding()
                  .background(
                    RoundedRectangle(cornerRadius: 12)
                      .stroke(Color.white.opacity(0.3), lineWidth: 1)
                  )
              }
            }
            
            Button(action: currentStep < steps.count - 1 ? nextStep : completeOnboarding) {
              Text(currentStep < steps.count - 1 ? "Next" : "Get Started")
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                  RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                )
            }
          }
          .padding(.horizontal)
        }
        
        Spacer()
      }
    }
  }
  
  private func nextStep() {
    withAnimation(.easeInOut(duration: 0.5)) {
      currentStep += 1
    }
  }
  
  private func previousStep() {
    withAnimation(.easeInOut(duration: 0.5)) {
      currentStep -= 1
    }
  }
  
  private func completeOnboarding() {
    appState.completeOnboarding()
  }
}

struct OnboardingStep {
  let title: String
  let description: String
  let instruction: String
  let icon: String
}

#Preview {
  OnboardingView(appState: AppState())
}