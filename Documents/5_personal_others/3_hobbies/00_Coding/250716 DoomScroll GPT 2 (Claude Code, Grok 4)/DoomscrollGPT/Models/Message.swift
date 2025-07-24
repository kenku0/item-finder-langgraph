import Foundation

struct Message: Identifiable, Codable {
  let id: UUID
  let content: String
  let role: Role
  let timestamp: Date
  let chunkIndex: Int
  let isAutoContinuation: Bool
  
  init(
    id: UUID = UUID(),
    content: String,
    role: Role,
    timestamp: Date = Date(),
    chunkIndex: Int = 0,
    isAutoContinuation: Bool = false
  ) {
    self.id = id
    self.content = content
    self.role = role
    self.timestamp = timestamp
    self.chunkIndex = chunkIndex
    self.isAutoContinuation = isAutoContinuation
  }
  
  enum Role: String, Codable {
    case user
    case assistant
    case system
  }
}

extension Message: Equatable {
  static func == (lhs: Message, rhs: Message) -> Bool {
    lhs.id == rhs.id && lhs.content == rhs.content
  }
}