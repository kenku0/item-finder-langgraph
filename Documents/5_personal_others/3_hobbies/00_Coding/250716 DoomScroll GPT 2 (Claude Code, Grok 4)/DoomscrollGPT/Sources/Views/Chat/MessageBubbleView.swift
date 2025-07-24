import SwiftUI

struct MessageBubbleView: View {
  let message: Message
  @State private var isVisible = false
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .top, spacing: 12) {
        if message.role == .user {
          Spacer()
          
          VStack(alignment: .trailing, spacing: 4) {
            Text(message.content)
              .font(.system(size: 16))
              .foregroundColor(.white)
              .multilineTextAlignment(.trailing)
              .padding(.horizontal, 12)
              .padding(.vertical, 8)
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(Color.white.opacity(0.15))
              )
            
            Text(formatTime(message.timestamp))
              .font(.caption2)
              .foregroundColor(.white.opacity(0.5))
          }
          .frame(maxWidth: .infinity * 0.8, alignment: .trailing)
          
        } else {
          VStack(alignment: .leading, spacing: 4) {
            Text(message.content)
              .font(.system(size: 16))
              .foregroundColor(.white)
              .multilineTextAlignment(.leading)
              .fixedSize(horizontal: false, vertical: true)
            
            Text(formatTime(message.timestamp))
              .font(.caption2)
              .foregroundColor(.white.opacity(0.5))
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          
          Spacer()
        }
      }
    }
    .opacity(isVisible ? 1 : 0)
    .offset(y: isVisible ? 0 : 10)
    .onAppear {
      withAnimation(.easeOut(duration: 0.4)) {
        isVisible = true
      }
    }
  }
  
  private func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    let calendar = Calendar.current
    
    if calendar.isDateInToday(date) {
      formatter.dateFormat = "h:mm a"
    } else {
      formatter.dateFormat = "MMM d, h:mm a"
    }
    
    return formatter.string(from: date)
  }
}

#Preview {
  VStack(spacing: 20) {
    MessageBubbleView(
      message: Message(
        content: "How can I help you today?",
        role: .assistant
      )
    )
    
    MessageBubbleView(
      message: Message(
        content: "Tell me about the latest developments in AI",
        role: .user
      )
    )
  }
  .padding()
  .background(Color.black)
}