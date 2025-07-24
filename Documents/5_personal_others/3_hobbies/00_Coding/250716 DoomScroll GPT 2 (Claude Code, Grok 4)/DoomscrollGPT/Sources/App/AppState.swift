import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
  @Published var isFirstLaunch = true
  @Published var hasCompletedOnboarding = false
  @Published var currentUser: User?
  @Published var isAuthenticated = false
  @Published var dailyScrollCount = 0
  @Published var freeScrollsUsed = 0
  @Published var lastResetDate = Date()
  
  private let userDefaults = UserDefaults.standard
  private let onboardingKey = "hasCompletedOnboarding"
  private let dailyScrollCountKey = "dailyScrollCount"
  private let freeScrollsUsedKey = "freeScrollsUsed"
  private let lastResetDateKey = "lastResetDate"
  
  init() {
    loadUserState()
    checkDailyReset()
  }
  
  func loadUserState() {
    hasCompletedOnboarding = userDefaults.bool(forKey: onboardingKey)
    dailyScrollCount = userDefaults.integer(forKey: dailyScrollCountKey)
    freeScrollsUsed = userDefaults.integer(forKey: freeScrollsUsedKey)
    
    if let lastResetData = userDefaults.object(forKey: lastResetDateKey) as? Date {
      lastResetDate = lastResetData
    }
    
    isFirstLaunch = !hasCompletedOnboarding
  }
  
  func completeOnboarding() {
    hasCompletedOnboarding = true
    isFirstLaunch = false
    userDefaults.set(true, forKey: onboardingKey)
  }
  
  func incrementScrollCount() {
    dailyScrollCount += 1
    if !isAuthenticated {
      freeScrollsUsed += 1
    }
    
    userDefaults.set(dailyScrollCount, forKey: dailyScrollCountKey)
    userDefaults.set(freeScrollsUsed, forKey: freeScrollsUsedKey)
  }
  
  func canScroll() -> Bool {
    if currentUser?.hasUnlimitedSubscription == true {
      return true
    }
    
    if !isAuthenticated && freeScrollsUsed >= 50 {
      return false
    }
    
    if isAuthenticated && dailyScrollCount >= 300 {
      return false
    }
    
    return true
  }
  
  private func checkDailyReset() {
    let calendar = Calendar.current
    if !calendar.isDate(lastResetDate, inSameDayAs: Date()) {
      resetDailyLimits()
    }
  }
  
  private func resetDailyLimits() {
    dailyScrollCount = 0
    lastResetDate = Date()
    
    userDefaults.set(0, forKey: dailyScrollCountKey)
    userDefaults.set(Date(), forKey: lastResetDateKey)
  }
  
  func authenticate(user: User) {
    currentUser = user
    isAuthenticated = true
  }
  
  func signOut() {
    currentUser = nil
    isAuthenticated = false
  }
}