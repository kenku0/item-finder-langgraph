import SwiftUI

@main
struct DoomscrollGPTApp: App {
  @StateObject private var appState = AppState()
  @StateObject private var subscriptionManager = SubscriptionManager()
  
  init() {
    // Setup default API key for testing
    APIConfiguration.shared.setupDefaultAPIKeyIfNeeded()
  }
  
  var body: some Scene {
    WindowGroup {
      if appState.hasCompletedOnboarding {
        ContentView()
          .environmentObject(subscriptionManager)
          .environmentObject(appState)
          .preferredColorScheme(.dark)
      } else {
        OnboardingView(appState: appState)
          .preferredColorScheme(.dark)
      }
    }
  }
}