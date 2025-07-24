import Foundation

struct Conversation: Identifiable, Codable {
  let id: UUID
  var messages: [Message]
  var title: String
  let createdAt: Date
  var updatedAt: Date
  var totalTokens: Int
  
  init(
    id: UUID = UUID(),
    messages: [Message] = [],
    title: String = "New Chat",
    createdAt: Date = Date(),
    updatedAt: Date = Date(),
    totalTokens: Int = 0
  ) {
    self.id = id
    self.messages = messages
    self.title = title
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.totalTokens = totalTokens
  }
  
  mutating func addMessage(_ message: Message) {
    messages.append(message)
    updatedAt = Date()
  }
  
  mutating func updateTitle(from firstMessage: String) {
    let maxLength = 30
    if firstMessage.count > maxLength {
      title = String(firstMessage.prefix(maxLength)) + "..."
    } else {
      title = firstMessage
    }
  }
  
  func estimateTokenCount() -> Int {
    let averageTokensPerChar = 0.25
    let totalChars = messages.reduce(0) { $0 + $1.content.count }
    return Int(Double(totalChars) * averageTokensPerChar)
  }
}