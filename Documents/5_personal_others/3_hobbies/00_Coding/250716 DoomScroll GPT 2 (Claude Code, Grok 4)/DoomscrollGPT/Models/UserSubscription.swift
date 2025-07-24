import Foundation

struct UserSubscription: Codable {
  var tier: SubscriptionTier
  var scrollsUsed: Int
  var dailyScrollsUsed: Int
  var lastResetDate: Date
  var expirationDate: Date?
  
  init(
    tier: SubscriptionTier = .free,
    scrollsUsed: Int = 0,
    dailyScrollsUsed: Int = 0,
    lastResetDate: Date = Date(),
    expirationDate: Date? = nil
  ) {
    self.tier = tier
    self.scrollsUsed = scrollsUsed
    self.dailyScrollsUsed = dailyScrollsUsed
    self.lastResetDate = lastResetDate
    self.expirationDate = expirationDate
  }
  
  enum SubscriptionTier: String, Codable {
    case free
    case signedInFree
    case premium
    
    var dailyLimit: Int? {
      switch self {
      case .free:
        return nil
      case .signedInFree:
        return 300
      case .premium:
        return nil
      }
    }
    
    var totalLimit: Int? {
      switch self {
      case .free:
        return 50
      case .signedInFree, .premium:
        return nil
      }
    }
  }
  
  mutating func resetDailyCountIfNeeded() {
    let calendar = Calendar.current
    if !calendar.isDateInToday(lastResetDate) {
      dailyScrollsUsed = 0
      lastResetDate = Date()
    }
  }
  
  mutating func incrementScrollCount() {
    scrollsUsed += 1
    dailyScrollsUsed += 1
  }
  
  mutating func canScroll() -> Bool {
    resetDailyCountIfNeeded()
    
    if let totalLimit = tier.totalLimit, scrollsUsed >= totalLimit {
      return false
    }
    
    if let dailyLimit = tier.dailyLimit, dailyScrollsUsed >= dailyLimit {
      return false
    }
    
    if tier == .premium, let expiration = expirationDate {
      return expiration > Date()
    }
    
    return true
  }
  
  func remainingScrolls() -> Int? {
    if tier == .premium {
      return nil
    }
    
    if let totalLimit = tier.totalLimit {
      return max(0, totalLimit - scrollsUsed)
    }
    
    if let dailyLimit = tier.dailyLimit {
      return max(0, dailyLimit - dailyScrollsUsed)
    }
    
    return nil
  }
}