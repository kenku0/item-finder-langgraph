import SwiftUI
import UIKit

struct ChatView: View {
  @EnvironmentObject var conversationManager: ConversationManager
  @EnvironmentObject var subscriptionManager: SubscriptionManager
  @EnvironmentObject var appState: AppState
  @ObservedObject var viewModel: ChatViewModel
  @State private var scrollOffset: CGFloat = 0
  @State private var showScrollIndicators = false
  @State private var hideUIElements = false
  @State private var lastGenerationTrigger: Date = Date()
  @State private var scrollViewHeight: CGFloat = 0
  @State private var contentHeight: CGFloat = 0
  @State private var isUserAtBottom = true
  @State private var autoScrollTimer: Timer?
  @State private var showScrollLimitAlert = false
  
  private let scrollThreshold: CGFloat = 100
  private let generationDebounceInterval: TimeInterval = 1.0
  
  @ViewBuilder
  private var messagesList: some View {
    ForEach(viewModel.currentConversation.messages.filter { !$0.isAutoContinuation }) { message in
      MessageBubbleView(message: message)
        .id(message.id)
        .transition(.asymmetric(
          insertion: .opacity.combined(with: .scale(scale: 0.8)),
          removal: .opacity
        ))
        .onAppear {
          if isLastMessage(message) {
            checkScrollPositionForGeneration()
          }
        }
    }
    .padding(.horizontal)
    .padding(.vertical, 8)
    
    // Invisible scroll trigger at the bottom
    Color.clear
      .frame(height: 1)
      .id("scrollTrigger")
      .onAppear {
        print("🎯 ChatView: Scroll trigger appeared - user at bottom")
        // Simplified: When this appears, user is at bottom - trigger generation
        if !viewModel.isGenerating && 
           !viewModel.currentConversation.messages.isEmpty &&
           appState.canScroll() &&
           subscriptionManager.canGenerateMore() &&
           Date().timeIntervalSince(lastGenerationTrigger) > generationDebounceInterval {
          
          print("✅ ChatView: Triggering generation from scroll trigger")
          print("   Current scroll counts - Free used: \(appState.freeScrollsUsed), Subscription remaining: \(subscriptionManager.subscription.remainingScrolls() ?? -1)")
          lastGenerationTrigger = Date()
          
          // Haptic feedback
          let impactFeedback = UIImpactFeedbackGenerator(style: .light)
          impactFeedback.impactOccurred()
          
          Task {
            await viewModel.generateNextChunk()
          }
        }
      }
  }
  
  @ViewBuilder
  private var loadingIndicator: some View {
    if viewModel.isGenerating {
      ProgressView()
        .progressViewStyle(CircularProgressViewStyle(tint: .white))
        .scaleEffect(0.8)
        .id("loading")
        .transition(.opacity.combined(with: .scale(scale: 0.8)))
        .padding(.vertical, 20)
    }
  }
  
  private var scrollPositionReader: some View {
    GeometryReader { geometry in
      Color.clear
        .preference(
          key: ScrollOffsetPreferenceKey.self,
          value: {
            // For normal scroll view, positive values mean scrolled down
            let value = -geometry.frame(in: .named("scroll")).minY
            print("📐 ChatView: GeometryReader scroll offset: \(value)")
            return value.isNaN || value.isInfinite ? 0 : value
          }()
        )
        .onAppear {
          let height = geometry.size.height
          contentHeight = height.isNaN || height.isInfinite ? 0 : height
        }
        .onChange(of: geometry.size.height) { _, newHeight in
          contentHeight = newHeight.isNaN || newHeight.isInfinite ? 0 : newHeight
        }
    }
  }
  
  var body: some View {
    ScrollViewReader { proxy in
        ZStack {
          Color.black
            .ignoresSafeArea()
          
          VStack(spacing: 0) {
              ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                  messagesList
                  loadingIndicator
                  
                  // Debug indicator showing scroll zone
                  if !viewModel.currentConversation.messages.isEmpty {
                    Text("Scroll here to generate more")
                      .font(.caption)
                      .foregroundColor(.white.opacity(0.3))
                      .padding(.vertical, 50)
                  }
                }
                .background(scrollPositionReader)
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                  print("🔄 ChatView: Preference change detected with value: \(value)")
                  // Guard against NaN values that cause CoreGraphics errors
                  if value.isNaN || value.isInfinite {
                    scrollOffset = 0
                  } else {
                    scrollOffset = value
                    // Check if we should trigger generation based on scroll position
                    checkScrollPositionForGeneration()
                  }
                  // Update isUserAtBottom based on scroll position
                  let distanceFromBottom = max(0, (contentHeight - scrollViewHeight) - scrollOffset)
                  let wasAtBottom = isUserAtBottom
                  isUserAtBottom = distanceFromBottom < 50.0
                  
                  if !isUserAtBottom && wasAtBottom {
                    stopAutoScroll()
                  }
    
                  updateUIVisibility()
                }
                .onChange(of: viewModel.currentConversation.messages.last?.content) {
                    let visibleMessages = viewModel.currentConversation.messages.filter { !$0.isAutoContinuation }
                    if isUserAtBottom, let lastMessageID = visibleMessages.last?.id {
                        withAnimation(.linear(duration: 1.0)) {
                            proxy.scrollTo(lastMessageID, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: viewModel.currentConversation.messages.count) {
                  withAnimation(.easeOut(duration: 0.5)) {
                    let visibleMessages = viewModel.currentConversation.messages.filter { !$0.isAutoContinuation }
                    if let lastMessage = visibleMessages.last {
                      proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                  }
                }
                .onChange(of: viewModel.isGenerating) { isGenerating in
                    if isGenerating && isUserAtBottom {
                        startAutoScroll(proxy: proxy)
                    } else {
                        stopAutoScroll()
                    }
                }
              }
              .background(
                GeometryReader { geometry in
                  Color.clear
                    .onAppear {
                      let height = geometry.size.height
                      scrollViewHeight = height.isNaN || height.isInfinite ? 0 : height
                      print("📐 ChatView: ScrollView viewport height: \(scrollViewHeight)")
                    }
                    .onChange(of: geometry.size.height) { _, newHeight in
                      scrollViewHeight = newHeight.isNaN || newHeight.isInfinite ? 0 : newHeight
                      print("📐 ChatView: ScrollView viewport height changed: \(scrollViewHeight)")
                    }
                }
              )
              
              if !hideUIElements {
                InputBarView(onSendMessage: handleSendMessage)
                  .transition(.move(edge: .bottom).combined(with: .opacity))
              }
          }
            
            if showScrollIndicators && viewModel.currentConversation.messages.filter({ !$0.isAutoContinuation }).count > 10 {
                ScrollIndicatorView(onScrollToTop: {
                    let visibleMessages = viewModel.currentConversation.messages.filter { !$0.isAutoContinuation }
                    if let firstMessage = visibleMessages.first {
                        withAnimation {
                            proxy.scrollTo(firstMessage.id, anchor: .top)
                        }
                    }
                }, onScrollToBottom: {
                    let visibleMessages = viewModel.currentConversation.messages.filter { !$0.isAutoContinuation }
                    if let lastMessageID = visibleMessages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastMessageID, anchor: .bottom)
                        }
                    }
                })
                .transition(.opacity)
            }
        }
        .onDisappear {
            stopAutoScroll()
        }
        .alert("Scroll Limit Reached", isPresented: $showScrollLimitAlert) {
            if !appState.isAuthenticated {
                Button("Sign In") {
                    // TODO: Navigate to sign in
                }
                Button("Cancel", role: .cancel) { }
            } else {
                Button("Upgrade") {
                    // TODO: Navigate to upgrade
                }
                Button("OK", role: .cancel) { }
            }
        } message: {
            if !appState.isAuthenticated {
                Text("You've used all 50 free scrolls. Sign in to get 300 daily scrolls!")
            } else {
                Text("You've reached your daily limit of 300 scrolls. Upgrade to unlimited for $5/month!")
            }
        }
    }
  }
  
  private func startAutoScroll(proxy: ScrollViewProxy) {
    stopAutoScroll()
    autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
      DispatchQueue.main.async {
        let visibleMessages = viewModel.currentConversation.messages.filter { !$0.isAutoContinuation }
        if let lastMessageID = visibleMessages.last?.id {
          withAnimation(.linear(duration: 0.05)) {
            proxy.scrollTo(lastMessageID, anchor: .bottom)
          }
        }
      }
    }
  }

  private func stopAutoScroll() {
    autoScrollTimer?.invalidate()
    autoScrollTimer = nil
  }

  private func isLastMessage(_ message: Message) -> Bool {
    let visibleMessages = viewModel.currentConversation.messages.filter { !$0.isAutoContinuation }
    return visibleMessages.last?.id == message.id
  }
  
  private func checkScrollPositionForGeneration() {
    // Ensure we have valid values
    guard !scrollOffset.isNaN && !scrollOffset.isInfinite,
          !contentHeight.isNaN && !contentHeight.isInfinite,
          !scrollViewHeight.isNaN && !scrollViewHeight.isInfinite else {
      print("⚠️ ChatView: Invalid scroll values detected")
      return
    }
    
    // Check if user has scrolled near the bottom
    // Now using normal scroll view (not inverted)
    let distanceFromBottom = (contentHeight - scrollViewHeight) - scrollOffset
    let shouldGenerate = distanceFromBottom < scrollThreshold && contentHeight > scrollViewHeight
    
    let wasAtBottom = isUserAtBottom
    isUserAtBottom = distanceFromBottom < 50.0
    
    if !isUserAtBottom && wasAtBottom {
      stopAutoScroll()
    }
    
    print("📏 ChatView: Scroll check - offset: \(scrollOffset), distance from bottom: \(distanceFromBottom), threshold: \(scrollThreshold), should generate: \(shouldGenerate)")
    print("   📊 Content height: \(contentHeight), ScrollView height: \(scrollViewHeight)")
    print("   📍 Messages count: \(viewModel.currentConversation.messages.count)")
    print("   ⚙️ Is generating: \(viewModel.isGenerating), Can scroll: \(appState.canScroll())")
    
    // Check conditions for generation
    if shouldGenerate && 
       !viewModel.isGenerating && 
       !viewModel.currentConversation.messages.isEmpty &&
       appState.canScroll() &&
       Date().timeIntervalSince(lastGenerationTrigger) > generationDebounceInterval {
      
      print("✅ ChatView: All conditions met for generation")
      print("   🚀 Triggering generateNextChunk()")
      
      // Haptic feedback when generation triggers
      let impactFeedback = UIImpactFeedbackGenerator(style: .light)
      impactFeedback.impactOccurred()
      
      lastGenerationTrigger = Date()
      Task {
          await viewModel.generateNextChunk()
      }
    } else {
      if viewModel.isGenerating {
        print("⏳ ChatView: Already generating")
      }
      if Date().timeIntervalSince(lastGenerationTrigger) <= generationDebounceInterval {
        print("⏱️ ChatView: Debounce interval not met")
      }
      if !shouldGenerate {
        print("📏 ChatView: Not at scroll threshold - distance: \(distanceFromBottom)")
      }
      if !appState.canScroll() {
        print("🚫 ChatView: Cannot scroll - limit reached")
        showScrollLimitAlert = true
      }
    }
  }
  
  private func updateUIVisibility() {
    // Guard against NaN values in scroll calculations
    let safeScrollOffset = scrollOffset.isNaN || scrollOffset.isInfinite ? 0 : scrollOffset
    let isScrolling = abs(safeScrollOffset) > 50

    if isUserAtBottom {
        // Don't hide UI if we are at the bottom, even during auto-scroll
        withAnimation(.easeInOut(duration: 0.3)) {
            hideUIElements = false
        }
    } else {
        withAnimation(.easeInOut(duration: 0.3)) {
            hideUIElements = isScrolling
        }
    }

    withAnimation(.easeInOut(duration: 0.3)) {
      showScrollIndicators = viewModel.currentConversation.messages.count > 10
    }
  }
  
  private func handleSendMessage(_ content: String) {
    if appState.canScroll() {
      viewModel.sendMessage(content)
    } else {
      // Here you can show an upgrade prompt if you have one.
      // For now, just printing.
      print("🚫 Cannot send message, scroll limit reached.")
      // Example: subscriptionManager.showUpgradePrompt = true
    }
  }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
  static var defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }
}

#Preview {
  let appState = AppState()
  let convoManager = ConversationManager()
  let subManager = SubscriptionManager()
  let chatViewModel = ChatViewModel(conversationManager: convoManager, subscriptionManager: subManager, appState: appState)
  
  return ChatView(viewModel: chatViewModel)
    .environmentObject(convoManager)
    .environmentObject(subManager)
    .environmentObject(appState)
    .preferredColorScheme(.dark)
}