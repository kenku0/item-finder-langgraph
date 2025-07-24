import Foundation
import Combine

@MainActor
class ChatViewModel: ObservableObject {
  private var conversationManager: ConversationManager
  private var subscriptionManager: SubscriptionManager
  private var appState: AppState
  private let apiService = GeminiAPIService()

  @Published var currentConversation: Conversation
  @Published var isGenerating: Bool = false
  
  private var cancellables = Set<AnyCancellable>()
  
  init(
    conversationManager: ConversationManager,
    subscriptionManager: SubscriptionManager,
    appState: AppState
  ) {
    self.conversationManager = conversationManager
    self.subscriptionManager = subscriptionManager
    self.appState = appState
    self.currentConversation = conversationManager.currentConversation
    
    // Subscribe to conversation changes, but only update for new conversations
    self.conversationManager.$currentConversation
      .dropFirst() // Ignore the initial value
      .receive(on: DispatchQueue.main)
      .sink { [weak self] newConversation in
          // Only update if the ID is different (i.e., user started a new chat)
          // This prevents overwriting during streaming
          if self?.currentConversation.id != newConversation.id {
              self?.currentConversation = newConversation
              print("🔄 ChatViewModel: Switched to new conversation with ID: \(newConversation.id)")
          }
      }
      .store(in: &cancellables)
  }
  
  func sendMessage(_ content: String) {
    guard !isGenerating, !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      return
    }
    
    let userMessage = Message(content: content, role: .user)
    
    // The VM now fully owns the active conversation.
    // We update our local copy only.
    var updatedConvo = currentConversation
    updatedConvo.addMessage(userMessage)
    if updatedConvo.messages.count <= 1 {
        updatedConvo.updateTitle(from: content)
    }
    self.currentConversation = updatedConvo
    
    Task {
      await streamResponse()
    }
  }

  func generateNextChunk() async {
    guard !isGenerating, appState.canScroll() && subscriptionManager.canGenerateMore() else {
        if !appState.canScroll() || !subscriptionManager.canGenerateMore() {
            print("🚫 ChatViewModel: Cannot scroll, limit reached.")
            print("   AppState canScroll: \(appState.canScroll()), SubscriptionManager canGenerate: \(subscriptionManager.canGenerateMore())")
            print("   Free scrolls used: \(appState.freeScrollsUsed), Subscription scrolls used: \(subscriptionManager.subscription.scrollsUsed)")
        }
        return
    }
    
    // Add continuation prompt using ChunkManager
    let chunkManager = ChunkManager()
    let continuationPrompt = chunkManager.createContinuationPrompt(from: currentConversation)
    let continuationMessage = Message(
        content: continuationPrompt,
        role: .user,
        isAutoContinuation: true
    )
    
    print("🔄 ChatViewModel: Adding continuation prompt for scroll-triggered generation")
    
    // Add the continuation prompt to conversation
    var updatedConvo = currentConversation
    updatedConvo.addMessage(continuationMessage)
    self.currentConversation = updatedConvo

    await streamResponse()
  }
  
  private func streamResponse() async {
    isGenerating = true
    print("🚀 ChatViewModel: Starting stream response generation")

    let messagesForAPI = currentConversation.messages.map { message -> [String: String] in
        return ["role": message.role.rawValue, "content": message.content]
    }
    
    print("📊 ChatViewModel: Current conversation has \(messagesForAPI.count) messages")

    let assistantMessageId = UUID()
    let emptyMessage = Message(id: assistantMessageId, content: "...", role: .assistant)

    // Update our local copy only.
    var updatedConvo = currentConversation
    updatedConvo.addMessage(emptyMessage)
    self.currentConversation = updatedConvo
    
    print("📝 ChatViewModel: Added placeholder assistant message with ID: \(assistantMessageId)")

    do {
        let stream = try await apiService.streamCompletion(messages: messagesForAPI)
        try await handleStream(stream, for: assistantMessageId)
    } catch {
        handleError(error, for: assistantMessageId)
    }
    
    isGenerating = false
    appState.incrementScrollCount()
    subscriptionManager.incrementScrollCount()
    
    print("📊 ChatViewModel: Scroll count updated - AppState free scrolls: \(appState.freeScrollsUsed), SubscriptionManager remaining: \(subscriptionManager.subscription.remainingScrolls() ?? -1)")
    
    // At the very end, sync the final state back to the manager for persistence.
    conversationManager.replaceCurrentConversation(with: self.currentConversation)
    print("🏁 ChatViewModel: Stream response finished and conversation synced to manager.")
  }
  
  private func handleStream(_ stream: AsyncThrowingStream<String, Error>, for messageId: UUID) async throws {
    var accumulatedContent = ""
    
    for try await chunk in stream {
        accumulatedContent += chunk
        print("📝 ChatViewModel: Chunk received, new content: '\(accumulatedContent.prefix(100))...'")
        
        // To trigger @Published update for struct, create a new Conversation instance
        var updatedConversation = currentConversation
        if let index = updatedConversation.messages.firstIndex(where: { $0.id == messageId }) {
            let oldMessage = updatedConversation.messages[index]
            updatedConversation.messages[index] = Message(
                id: messageId,
                content: accumulatedContent,
                role: .assistant,
                timestamp: oldMessage.timestamp
            )
            // Reassign to trigger publisher
            self.currentConversation = updatedConversation
            print("🔄 ChatViewModel: Updated conversation and triggered UI refresh")
        }
    }
    
    // The manager is no longer updated here.
  }

  private func handleError(_ error: Error, for messageId: UUID) {
    print("❌ ChatViewModel: Error receiving stream: \(error.localizedDescription)")
    let errorMessage = "Sorry, I ran into an error: \(error.localizedDescription)"

    // Update the local message to show the error
    var updatedConversation = currentConversation
    if let index = updatedConversation.messages.firstIndex(where: { $0.id == messageId }) {
        let oldMessage = updatedConversation.messages[index]
        updatedConversation.messages[index] = Message(
            id: messageId,
            content: errorMessage,
            role: .assistant,
            timestamp: oldMessage.timestamp
        )
        // Reassign to trigger publisher
        self.currentConversation = updatedConversation
    }
    
    // The manager is no longer updated here.
  }
}
