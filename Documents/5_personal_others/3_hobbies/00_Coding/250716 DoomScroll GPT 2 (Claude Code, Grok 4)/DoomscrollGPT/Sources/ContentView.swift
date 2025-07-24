import SwiftUI

struct ContentView: View {
  @StateObject private var conversationManager = ConversationManager()
  @StateObject private var subscriptionManager = SubscriptionManager()
  @StateObject private var appState = AppState()
  @StateObject private var chatViewModel: ChatViewModel
  @State private var showHistory = false
  
  init() {
      let conversationManager = ConversationManager()
      let subscriptionManager = SubscriptionManager()
      let appState = AppState()
      
      _conversationManager = StateObject(wrappedValue: conversationManager)
      _subscriptionManager = StateObject(wrappedValue: subscriptionManager)
      _appState = StateObject(wrappedValue: appState)
      _chatViewModel = StateObject(wrappedValue: ChatViewModel(
          conversationManager: conversationManager,
          subscriptionManager: subscriptionManager,
          appState: appState
      ))
  }

  var body: some View {
    ZStack {
      Color.black
        .ignoresSafeArea()
      
      VStack(spacing: 0) {
        // Header
        HStack {
          Button(action: { withAnimation { showHistory.toggle() } }) {
            Image(systemName: "line.3.horizontal")
              .font(.title3)
              .foregroundColor(.white)
          }
          .keyboardShortcut("j", modifiers: .command)
          
          Spacer()
          
          Text("Doomscroll GPT")
            .font(.title3)
            .fontWeight(.medium)
            .foregroundColor(.white)
          
          Spacer()
          
          Button(action: { conversationManager.startNewConversation() }) {
            Image(systemName: "square.and.pencil")
              .font(.title3)
              .foregroundColor(.white)
          }
          .keyboardShortcut("n", modifiers: .command)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        
        // Chat Interface
        ChatView(viewModel: chatViewModel)
          .environmentObject(conversationManager)
          .environmentObject(subscriptionManager)
          .environmentObject(appState)
      }
      
      if showHistory {
        HistoryView(isShowing: $showHistory)
          .environmentObject(conversationManager)
          .environmentObject(subscriptionManager)
          .environmentObject(appState)
          .transition(.move(edge: .leading))
          .zIndex(1)
      }
    }
  }
}

#Preview {
  ContentView()
    .preferredColorScheme(.dark)
}