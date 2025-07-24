import Foundation
import Combine

class ConversationManager: ObservableObject {
  @Published var currentConversation: Conversation
  @Published var conversations: [Conversation] = []
  @Published var hasStartedAnyConversation = false
  
  private let storage = ConversationStorage()
  
  init() {
    self.currentConversation = Conversation()
    loadConversations()
  }
  
  func loadConversations() {
    conversations = storage.loadConversations()
    if let lastConversation = conversations.first {
      currentConversation = lastConversation
    } else {
      // Ensure there's always a conversation to start with
      conversations.append(currentConversation)
    }
    hasStartedAnyConversation = conversations.count > 1 || !currentConversation.messages.isEmpty
  }
  
  func saveConversations() {
      storage.saveConversations(conversations)
  }

  func replaceCurrentConversation(with conversation: Conversation) {
    if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
      conversations[index] = conversation
    } else {
      // This case handles the very first message of a new chat
      conversations[0] = conversation
    }
    self.currentConversation = conversation
    saveConversations()
  }
  
  func startNewConversation() {
    let newConversation = Conversation()
    conversations.insert(newConversation, at: 0)
    currentConversation = newConversation
    saveConversations()
  }
  
  func selectConversation(_ conversation: Conversation) {
    currentConversation = conversation
  }
  
  func deleteConversation(_ conversation: Conversation) {
    // Save the ID of the deleted conversation
    let deletedId = conversation.id
    
    // Remove it from the array
    conversations.removeAll { $0.id == deletedId }
    
    // If the deleted one was the current one, select the top one or create a new one
    if currentConversation.id == deletedId {
      currentConversation = conversations.first ?? Conversation()
      if conversations.isEmpty {
          conversations.append(currentConversation)
      }
    }
    
    saveConversations()
  }
}

class ConversationStorage {
  private let userDefaults = UserDefaults.standard
  private let conversationsKey = "doomscroll_conversations"
  
  func loadConversations() -> [Conversation] {
    guard let data = userDefaults.data(forKey: conversationsKey),
          let conversations = try? JSONDecoder().decode([Conversation].self, from: data) else {
      return []
    }
    return conversations
  }
  
  func saveConversations(_ conversations: [Conversation]) {
    if let data = try? JSONEncoder().encode(conversations) {
      userDefaults.set(data, forKey: conversationsKey)
    }
  }
}