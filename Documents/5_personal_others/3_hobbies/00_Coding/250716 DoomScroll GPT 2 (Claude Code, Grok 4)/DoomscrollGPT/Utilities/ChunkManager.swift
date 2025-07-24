import Foundation

class ChunkManager {
  private let maxTokens = 131000
  private let maxMessagesInContext = 10
  private let averageTokensPerCharacter = 0.25
  
  var currentChunkIndex = 0
  
  func prepareMessagesForAPI(conversation: Conversation, newPrompt: String) -> [[String: String]] {
    var messages: [[String: String]] = []
    
    messages.append(createSystemMessage())
    
    let recentMessages = getRecentMessages(from: conversation)
    
    for message in recentMessages {
      messages.append([
        "role": message.role.rawValue,
        "content": message.content
      ])
    }
    
    if !newPrompt.isEmpty {
      // Check if the last message is the same as the new prompt to avoid duplicates
      if messages.last?["content"] != newPrompt {
        messages.append([
          "role": "user",
          "content": newPrompt
        ])
      }
    }
    
    // Remove any consecutive duplicate messages
    messages = removeDuplicateMessages(messages)
    
    return limitMessagesToTokenCount(messages)
  }
  
  func prepareMessagesForContinuation(conversation: Conversation, continuationPrompt: String) -> [[String: String]] {
    var messages: [[String: String]] = []
    
    messages.append(createSystemMessage())
    
    let recentMessages = getRecentMessages(from: conversation)
    
    for message in recentMessages {
      messages.append([
        "role": message.role.rawValue,
        "content": message.content
      ])
    }
    
    messages.append([
      "role": "user",
      "content": continuationPrompt
    ])
    
    currentChunkIndex += 1
    
    return limitMessagesToTokenCount(messages)
  }
  
  func createContinuationPrompt(from conversation: Conversation) -> String {
    return "Continue expanding on what you were just discussing. Go deeper into the topic and explore the next logical aspect. Provide more details, examples, or related insights. Keep the conversation flowing naturally."
  }
  
  private func createSystemMessage() -> [String: String] {
    [
      "role": "system",
      "content": "You are Gemini, an endlessly curious and insightful conversational partner. Your purpose is to engage the user in a continuous, unfolding dialogue. Generate the next logical portion of your response based on the history provided. Your tone is intelligent, slightly philosophical, but always accessible. Keep the flow going. Never say 'In summary' or 'To conclude'. Simply continue the thought. Be concise but profound."
    ]
  }
  
  private func getRecentMessages(from conversation: Conversation) -> [Message] {
    let sortedMessages = conversation.messages.sorted { $0.timestamp < $1.timestamp }
    
    if sortedMessages.count <= maxMessagesInContext {
      return sortedMessages
    }
    
    let recentMessages = Array(sortedMessages.suffix(maxMessagesInContext))
    
    if shouldSummarizeOlderMessages(conversation: conversation) {
      return summarizeAndIncludeMessages(
        recentMessages: recentMessages,
        allMessages: sortedMessages
      )
    }
    
    return recentMessages
  }
  
  private func shouldSummarizeOlderMessages(conversation: Conversation) -> Bool {
    let totalTokens = estimateTokenCount(for: conversation.messages)
    return totalTokens > maxTokens * 2 / 3
  }
  
  private func summarizeAndIncludeMessages(
    recentMessages: [Message],
    allMessages: [Message]
  ) -> [Message] {
    let olderMessages = Array(allMessages.prefix(allMessages.count - maxMessagesInContext))
    
    let summary = createSummary(from: olderMessages)
    let summaryMessage = Message(
      content: summary,
      role: .system,
      timestamp: olderMessages.first?.timestamp ?? Date()
    )
    
    return [summaryMessage] + recentMessages
  }
  
  private func createSummary(from messages: [Message]) -> String {
    let userMessages = messages.filter { $0.role == .user }
    let assistantMessages = messages.filter { $0.role == .assistant }
    
    var summary = "Previous conversation summary:\n"
    
    if !userMessages.isEmpty {
      let userTopics = userMessages.map { message in
        String(message.content.prefix(100))
      }.joined(separator: "; ")
      summary += "User discussed: \(userTopics)\n"
    }
    
    if !assistantMessages.isEmpty {
      let assistantTopics = assistantMessages.map { message in
        String(message.content.prefix(100))
      }.joined(separator: "; ")
      summary += "Assistant covered: \(assistantTopics)\n"
    }
    
    return summary
  }
  
  private func limitMessagesToTokenCount(_ messages: [[String: String]]) -> [[String: String]] {
    var result: [[String: String]] = []
    var currentTokens = 0
    
    for message in messages {
      let messageTokens = estimateTokenCount(for: message["content"] ?? "")
      
      if currentTokens + messageTokens > maxTokens {
        break
      }
      
      result.append(message)
      currentTokens += messageTokens
    }
    
    return result
  }
  
  private func estimateTokenCount(for messages: [Message]) -> Int {
    let totalCharacters = messages.reduce(0) { $0 + $1.content.count }
    return Int(Double(totalCharacters) * averageTokensPerCharacter)
  }
  
  private func estimateTokenCount(for text: String) -> Int {
    return Int(Double(text.count) * averageTokensPerCharacter)
  }
  
  private func removeDuplicateMessages(_ messages: [[String: String]]) -> [[String: String]] {
    guard messages.count > 1 else { return messages }
    
    var result: [[String: String]] = []
    var previousMessage: [String: String]? = nil
    
    for message in messages {
      // Skip if this message is identical to the previous one
      if let prev = previousMessage,
         prev["role"] == message["role"],
         prev["content"] == message["content"] {
        print("⚠️ ChunkManager: Removing duplicate message: \(message["content"]?.prefix(50) ?? "")...")
        continue
      }
      
      result.append(message)
      previousMessage = message
    }
    
    return result
  }
}