import SwiftUI

struct ScrollIndicatorView: View {
  @State private var isAnimating = false
  
  var onScrollToTop: (() -> Void)? = nil
  var onScrollToBottom: (() -> Void)? = nil
  
  var body: some View {
    VStack {
      Spacer()
      
      HStack {
        Spacer()
        
        VStack(spacing: 16) {
          Button(action: { onScrollToTop?() }) {
            Image(systemName: "chevron.up")
              .font(.system(size: 14, weight: .medium))
              .foregroundColor(.white.opacity(0.8))
              .padding(8)
              .background(
                Circle()
                  .fill(Color.white.opacity(0.1))
                  .overlay(
                    Circle()
                      .stroke(Color.white.opacity(0.2), lineWidth: 1)
                  )
              )
          }
          
          Button(action: { onScrollToBottom?() }) {
            Image(systemName: "chevron.down")
              .font(.system(size: 14, weight: .medium))
              .foregroundColor(.white.opacity(0.8))
              .padding(8)
              .background(
                Circle()
                  .fill(Color.white.opacity(0.1))
                  .overlay(
                    Circle()
                      .stroke(Color.white.opacity(0.2), lineWidth: 1)
                  )
              )
          }
          .scaleEffect(isAnimating ? 1.1 : 1.0)
          .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
        }
        .padding(.trailing, 16)
      }
      
      Spacer()
    }
    .onAppear {
      isAnimating = true
    }
  }
}

#Preview {
  ScrollIndicatorView()
    .background(Color.black)
}