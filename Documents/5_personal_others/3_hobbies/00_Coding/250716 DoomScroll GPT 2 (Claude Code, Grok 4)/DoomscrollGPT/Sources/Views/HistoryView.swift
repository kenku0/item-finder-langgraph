import SwiftUI

struct HistoryView: View {
  @Binding var isShowing: Bool
  @EnvironmentObject var conversationManager: ConversationManager
  @EnvironmentObject var subscriptionManager: SubscriptionManager
  @EnvironmentObject var appState: AppState
  @State private var selectedConversation: Conversation?
  @State private var showSettings = false
  
  var body: some View {
    HStack(spacing: 0) {
      VStack(alignment: .leading, spacing: 0) {
        HStack {
          Text("History")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.white)
          
          Spacer()
          
          Button(action: { withAnimation { isShowing = false } }) {
            Image(systemName: "xmark")
              .font(.system(size: 16))
              .foregroundColor(.white.opacity(0.7))
          }
        }
        .padding()
        .background(Color.black)
        
        ScrollView {
          LazyVStack(spacing: 1) {
            ForEach(conversationManager.conversations) { conversation in
              ConversationRowView(
                conversation: conversation,
                isSelected: selectedConversation?.id == conversation.id
              )
              .onTapGesture {
                selectConversation(conversation)
              }
              .contextMenu {
                Button(role: .destructive) {
                  deleteConversation(conversation)
                } label: {
                  Label("Delete", systemImage: "trash")
                }
              }
            }
          }
        }
        .background(Color.black)
        
        Button(action: { showSettings = true }) {
          HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
              .font(.system(size: 24))
            Text("Account")
              .font(.system(size: 16, weight: .medium))
            Spacer()
          }
          .padding()
          .foregroundColor(.white)
        }
        .background(Color.white.opacity(0.1))
        .sheet(isPresented: $showSettings) {
          SettingsView()
            .environmentObject(subscriptionManager)
            .environmentObject(appState)
        }
        
        Spacer()
      }
      .frame(width: 280)
      .background(Color.black)
      .overlay(
        Rectangle()
          .fill(Color.white.opacity(0.1))
          .frame(width: 1),
        alignment: .trailing
      )
      
      Spacer()
        .background(Color.black.opacity(0.5))
        .onTapGesture {
          withAnimation {
            isShowing = false
          }
        }
    }
  }
  
  private func selectConversation(_ conversation: Conversation) {
    selectedConversation = conversation
    conversationManager.selectConversation(conversation)
    withAnimation {
      isShowing = false
    }
  }
  
  private func deleteConversation(_ conversation: Conversation) {
    conversationManager.deleteConversation(conversation)
  }
}

struct ConversationRowView: View {
  let conversation: Conversation
  let isSelected: Bool
  
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(conversation.title)
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(.white)
        .lineLimit(2)
      
      if !conversation.messages.isEmpty {
        Text(conversation.messages.first?.content ?? "")
          .font(.system(size: 14))
          .foregroundColor(.white.opacity(0.6))
          .lineLimit(2)
      }
      
      Text(formatDate(conversation.updatedAt))
        .font(.system(size: 12))
        .foregroundColor(.white.opacity(0.5))
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      Rectangle()
        .fill(isSelected ? Color.white.opacity(0.1) : Color.clear)
    )
    .overlay(
      Rectangle()
        .fill(Color.white.opacity(0.1))
        .frame(height: 1),
      alignment: .bottom
    )
  }
  
  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    let calendar = Calendar.current
    
    if calendar.isDateInToday(date) {
      formatter.dateFormat = "h:mm a"
      return "Today, \(formatter.string(from: date))"
    } else if calendar.isDateInYesterday(date) {
      formatter.dateFormat = "h:mm a"
      return "Yesterday, \(formatter.string(from: date))"
    } else {
      formatter.dateFormat = "MMM d, h:mm a"
      return formatter.string(from: date)
    }
  }
}

#Preview {
  HistoryView(isShowing: .constant(true))
    .environmentObject(ConversationManager())
    .environmentObject(SubscriptionManager())
    .environmentObject(AppState())
    .background(Color.black)
}