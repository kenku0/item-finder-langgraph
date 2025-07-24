import Foundation

struct User: Codable, Identifiable {
  let id: UUID
  let email: String?
  let createdAt: Date
  let subscriptionStatus: SubscriptionStatus
  let dailyScrollCount: Int
  let totalScrollsUsed: Int
  
  var hasUnlimitedSubscription: Bool {
    subscriptionStatus == .unlimited
  }
  
  var canScroll: Bool {
    switch subscriptionStatus {
    case .free:
      return dailyScrollCount < 300
    case .unlimited:
      return true
    }
  }
  
  init(
    id: UUID = UUID(),
    email: String? = nil,
    createdAt: Date = Date(),
    subscriptionStatus: SubscriptionStatus = .free,
    dailyScrollCount: Int = 0,
    totalScrollsUsed: Int = 0
  ) {
    self.id = id
    self.email = email
    self.createdAt = createdAt
    self.subscriptionStatus = subscriptionStatus
    self.dailyScrollCount = dailyScrollCount
    self.totalScrollsUsed = totalScrollsUsed
  }
}

enum SubscriptionStatus: String, Codable, CaseIterable {
  case free = "free"
  case unlimited = "unlimited"
  
  var displayName: String {
    switch self {
    case .free:
      return "Free (300 daily scrolls)"
    case .unlimited:
      return "Unlimited ($8/month)"
    }
  }
  
  var monthlyPrice: String {
    switch self {
    case .free:
      return "$0"
    case .unlimited:
      return "$8"
    }
  }
}