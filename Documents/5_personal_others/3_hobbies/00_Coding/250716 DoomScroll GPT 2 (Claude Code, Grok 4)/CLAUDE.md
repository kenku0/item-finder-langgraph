# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
DoomscrollGPT is a native iOS app that provides an "infinite scrolling" conversational AI experience powered by Google's Gemini 2.5 Flash-Lite API. The core innovation is that users scroll down to generate more AI content, creating an addictive "doomscrolling" experience for conversations.

Key Features:
- Infinite scroll-triggered AI generation  
- Direct REST API integration with Gemini 2.5 Flash-Lite (no external SDK dependencies)
- Freemium model: 50 free scrolls, then 300 daily after signup, $5/month unlimited
- Minimalist black-and-white UI
- Voice input support
- Real-time streaming responses with auto-scroll

## Development Commands

### Building and Running
```bash
# Open project in Xcode
open DoomscrollGPT.xcodeproj

# Build for simulator
xcodebuild -project DoomscrollGPT.xcodeproj -scheme DoomscrollGPT -sdk iphonesimulator build

# Run tests
xcodebuild test -project DoomscrollGPT.xcodeproj -scheme DoomscrollGPT -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Run a single test file
xcodebuild test -project DoomscrollGPT.xcodeproj -scheme DoomscrollGPT -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:DoomscrollGPTTests/[TestClassName]

# Clean the build folder
xcodebuild clean -project DoomscrollGPT.xcodeproj -scheme DoomscrollGPT

# Run SwiftLint
swiftlint

# Run SwiftLint autocorrect
swiftlint --fix
```

### Testing Utilities
```bash
# Test Gemini API streaming
swift test_streaming.swift

# Run Swift Package Manager tests
swift test

# Build Swift Package
swift build
```

## Architecture Overview

The project follows MVVM pattern with a recent architectural change to improve streaming UI updates. ChatViewModel now maintains its own local copy of the conversation during streaming operations.

### Key Directories
- `Sources/` - Main application code
  - `App/` - App lifecycle (DoomscrollGPTApp.swift, AppState.swift)
  - `Views/` - SwiftUI views organized by feature
  - `ContentView.swift` - Root view with tab navigation, initializes ChatViewModel
- `ViewModels/` - Business logic and state management
- `Models/` - Data structures (Message, Conversation, User, UserSubscription)
- `Services/` - API and external service integrations
- `Utilities/` - Helper classes and extensions
- `Resources/` - Assets and configuration files

### API Configuration
- Model: `gemini-2.5-flash-lite` (Released January 2025 - fastest and most cost-efficient)
- Endpoint: `https://generativelanguage.googleapis.com/v1beta`
- Method: Server-Sent Events (SSE) for streaming
- Context Window: 1 million token context with entire conversation history sent each request
- Key Features: 1.5x faster than 2.0 Flash at lower cost, optimized for high-volume tasks

### Security
API keys are stored securely in iOS Keychain via `KeychainHelper.swift`. A default key exists in `APIConfiguration.swift` for testing.

## Critical Implementation Details & Patterns

### The "Doomscroll" Logic (ChatView.swift)
The core feature monitors scroll position in a standard ScrollView:

1. **Standard ScrollView**: Uses normal top-to-bottom scrolling (not inverted)
2. **Trigger Threshold**: Generation at 100px from bottom (`scrollThreshold: CGFloat = 100`)
3. **Debounce**: 1-second interval prevents rapid requests
4. **Validation**: Scroll offsets validated for NaN/Infinite values
5. **Auto-scroll**: Timer-based scrolling at 50ms intervals (20 FPS) during streaming when user is at bottom

### Streaming Response Architecture (ChatViewModel.swift)
Recent refactoring improves UI responsiveness:
1. ChatViewModel maintains its own `@Published var currentConversation`
2. During streaming, only the local copy is updated to trigger immediate UI refreshes
3. At the end of streaming, the conversation is synced back to ConversationManager via `replaceCurrentConversation()`
4. This avoids conflicts between streaming updates and manager updates

```swift
// Update local copy during streaming
var updatedConversation = currentConversation
updatedConversation.messages[index] = Message(...)
self.currentConversation = updatedConversation // Triggers UI update

// Sync back to manager after streaming completes
conversationManager.replaceCurrentConversation(with: self.currentConversation)
```

### Streaming Response Parser (GeminiAPIService.swift)
Resilient parser handles SSE streaming:
1. Processes lines with brace counting for complete JSON objects
2. Primary extraction via regex: `"text"\s*:\s*"([^"\\]*(\\.[^"\\]*)*)"`
3. Immediate text extraction for progressive display
4. Handles edge cases: malformed JSON, array boundaries, trailing commas

### ConversationManager Pattern
- Uses `replaceCurrentConversation()` instead of direct property updates
- Ensures proper persistence and UI synchronization
- Handles edge cases like first message of new chat

### Continuation Prompts (ChunkManager.swift)
- Uses "user" role for API requirements
- Topic-agnostic prompts for natural continuation: "Continue expanding on what you were just discussing..."
- De-duplicated conversation history in each request
- Maintains max 10 messages in context with 131,000 token limit
- Implements message summarization for older conversations

## Common Issues & Solutions

**Responses show only "..."**: 
- Ensure ChatViewModel is properly initialized with dependencies in ContentView
- Verify the streaming update creates new Conversation instances (struct value semantics)
- Check that ChatView uses `viewModel.currentConversation` not `conversationManager.currentConversation`

**Wrong message order**: Remove any `.reversed()` on messages array

**JSON parsing errors**: Use regex extraction as primary method

**Scroll-to-generate not triggering**: Validate scroll offset values

**NaN CoreGraphics errors**: Add validation checks for geometry values

## System Prompts

### Main System Prompt (GeminiAPIService.swift)
```
You are an advanced AI assistant. Your purpose is to provide comprehensive, detailed responses that maximize the value of each interaction. When continuing a conversation, expand thoughtfully on previous topics while introducing related concepts naturally. Be authoritative, insightful, and thorough. Generate substantial content that rewards the user's scrolling behavior. Your responses should be in plain text only - do not use any markdown formatting, code blocks, or special characters for emphasis. Do not ask questions or prompt for user interaction.
```

### Continuation Prompt (ChunkManager.swift)
```
Continue expanding on what you were just discussing. Go deeper into the topic and explore the next logical aspect. Provide more details, examples, or related insights. Keep the conversation flowing naturally.
```

## Testing Strategy
- **Unit Tests**: ViewModels, Services, business logic
- **UI Tests**: User flows, scroll-to-generate triggers
- **Integration Tests**: API response handling with mocks
- **Performance Tests**: Large conversation scrolling

## SwiftLint Configuration
Project uses custom SwiftLint rules based on Airbnb style guide (.swiftlint.yml):
- Line length: warning 100, error 120
- Force unwrapping/casting: error
- Custom rule: No direct print/NSLog (use os_log)
- Disabled rules: trailing_whitespace, todo, unused_import
- Many opt-in rules enabled for code quality
- File/function/type body length limits enforced
- Cyclomatic complexity: warning 10, error 20

## Troubleshooting

### UI Not Updating During Streaming
1. Verify ChatViewModel owns its local conversation copy
2. Check that UI observes `viewModel.currentConversation` not manager's
3. Ensure struct updates create new instances (value semantics)
4. Confirm ContentView properly initializes and passes ChatViewModel

### Build Errors
- Remove Info.plist from Copy Bundle Resources if getting duplicate errors
- Ensure entitlements file exists at the expected path
- Clean derived data if seeing persistent module errors

## Current Implementation Status
✅ Complete UI implementation  
✅ Direct API integration with streaming  
✅ Doomscroll logic functional  
✅ Subscription management  
✅ Onboarding and settings  
✅ Core message ordering stable  
✅ Streaming UI updates fixed via local conversation copy  
✅ Swift Package Manager support  
🔄 Voice input integration incomplete  
🔄 Performance optimization needed for large conversations

## Project Structure Notes
- This is an Xcode project with Swift Package Manager support (Package.swift exists)
- Minimum iOS deployment target: iOS 16.0
- Swift tools version: 5.9
- No external dependencies - uses only native iOS frameworks