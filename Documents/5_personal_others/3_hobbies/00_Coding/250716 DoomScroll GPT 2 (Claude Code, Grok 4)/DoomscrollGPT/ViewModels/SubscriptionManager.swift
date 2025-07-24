import Foundation
import Combine

class SubscriptionManager: ObservableObject {
  @Published var subscription: UserSubscription
  @Published var showUpgradePrompt = false
  
  private let storage = SubscriptionStorage()
  
  init() {
    self.subscription = storage.loadSubscription()
  }
  
  func canGenerateMore() -> Bool {
    subscription.resetDailyCountIfNeeded()
    return subscription.canScroll()
  }
  
  func incrementScrollCount() {
    subscription.incrementScrollCount()
    storage.saveSubscription(subscription)
    
    if !subscription.canScroll() {
      showUpgradePrompt = true
    }
  }
  
  func upgradeToSignedInFree() {
    subscription.tier = .signedInFree
    subscription.dailyScrollsUsed = 0
    subscription.lastResetDate = Date()
    storage.saveSubscription(subscription)
  }
  
  func upgradeToPremium(expirationDate: Date) {
    subscription.tier = .premium
    subscription.expirationDate = expirationDate
    storage.saveSubscription(subscription)
  }
  
  func getRemainingScrollsText() -> String? {
    guard let remaining = subscription.remainingScrolls() else {
      return nil
    }
    
    switch subscription.tier {
    case .free:
      return "\(remaining) scrolls remaining"
    case .signedInFree:
      return "\(remaining) scrolls today"
    case .premium:
      return nil
    }
  }
}

class SubscriptionStorage {
  private let userDefaults = UserDefaults.standard
  private let subscriptionKey = "doomscroll_subscription"
  
  func loadSubscription() -> UserSubscription {
    guard let data = userDefaults.data(forKey: subscriptionKey),
          let subscription = try? JSONDecoder().decode(UserSubscription.self, from: data) else {
      return UserSubscription()
    }
    return subscription
  }
  
  func saveSubscription(_ subscription: UserSubscription) {
    if let data = try? JSONEncoder().encode(subscription) {
      userDefaults.set(data, forKey: subscriptionKey)
    }
  }
}