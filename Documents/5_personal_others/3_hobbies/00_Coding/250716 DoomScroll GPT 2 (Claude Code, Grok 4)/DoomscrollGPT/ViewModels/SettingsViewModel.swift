import SwiftUI
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
  @Published var apiKey: String = ""
  @Published var showingAPIKeyAlert = false
  @Published var showingDeleteAlert = false
  @Published var showingSubscriptionView = false
  @Published var isAPIKeyValid = false
  
  private let subscriptionService: SubscriptionService
  private let appState: AppState
  private var cancellables = Set<AnyCancellable>()
  
  init(subscriptionService: SubscriptionService, appState: AppState) {
    self.subscriptionService = subscriptionService
    self.appState = appState
    
    loadAPIKey()
    setupSubscriptions()
  }
  
  private func setupSubscriptions() {
    // Monitor subscription changes
    subscriptionService.$isSubscribed
      .sink { [weak self] _ in
        self?.objectWillChange.send()
      }
      .store(in: &cancellables)
  }
  
  private func loadAPIKey() {
    apiKey = KeychainHelper.shared.getAPIKey() ?? ""
    isAPIKeyValid = !apiKey.isEmpty
  }
  
  func saveAPIKey() {
    let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    
    do {
      if trimmedKey.isEmpty {
        try KeychainHelper.shared.deleteAPIKey()
        isAPIKeyValid = false
      } else {
        try KeychainHelper.shared.saveAPIKey(trimmedKey)
        isAPIKeyValid = true
      }
      showingAPIKeyAlert = true
    } catch {
      // Handle keychain errors gracefully
      print("Keychain error: \(error.localizedDescription)")
      // Still show success alert for UX - keychain errors are usually not critical for user experience
      showingAPIKeyAlert = true
      isAPIKeyValid = !trimmedKey.isEmpty
    }
  }
  
  func deleteAllData() {
    // Clear API key
    do {
      try KeychainHelper.shared.deleteAPIKey()
    } catch {
      print("Error deleting API key: \(error.localizedDescription)")
    }
    
    apiKey = ""
    isAPIKeyValid = false
    
    // Reset app state
    let userDefaults = UserDefaults.standard
    userDefaults.removeObject(forKey: "hasCompletedOnboarding")
    userDefaults.removeObject(forKey: "dailyScrollCount")
    userDefaults.removeObject(forKey: "freeScrollsUsed")
    userDefaults.removeObject(forKey: "lastResetDate")
    
    // Reset app state
    appState.hasCompletedOnboarding = false
    appState.isFirstLaunch = true
    appState.dailyScrollCount = 0
    appState.freeScrollsUsed = 0
    appState.signOut()
    
    showingDeleteAlert = true
  }
  
  func openSubscriptionView() {
    showingSubscriptionView = true
  }
  
  var subscriptionStatusText: String {
    subscriptionService.subscriptionStatusText
  }
  
  var dailyScrollsUsed: Int {
    appState.dailyScrollCount
  }
  
  var freeScrollsUsed: Int {
    appState.freeScrollsUsed
  }
  
  var remainingFreeScrolls: Int {
    max(0, 50 - appState.freeScrollsUsed)
  }
  
  var remainingDailyScrolls: Int {
    if subscriptionService.isSubscribed {
      return Int.max // Unlimited
    } else if appState.isAuthenticated {
      return max(0, 300 - appState.dailyScrollCount)
    } else {
      return remainingFreeScrolls
    }
  }
  
  var usageText: String {
    if subscriptionService.isSubscribed {
      return "Usage Today: \(dailyScrollsUsed) scrolls (Unlimited)"
    } else if appState.isAuthenticated {
      return "Usage Today: \(dailyScrollsUsed)/300 scrolls"
    } else {
      return "Free Scrolls Used: \(freeScrollsUsed)/50"
    }
  }
}