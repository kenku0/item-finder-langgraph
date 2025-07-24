# Doomscroll GPT

An iOS app that provides an infinite scrolling conversational AI experience powered by Google's Gemini 2.0 Flash API.

## Features

- **Infinite Scrolling**: Seamless content generation triggered by scroll position
- **Voice Input**: Real-time speech recognition for hands-free interaction
- **Minimalistic Design**: Clean black-and-white interface
- **Subscription Tiers**: Free (50 scrolls), Signed-in Free (300 daily), Premium (unlimited)
- **Conversation History**: Persistent chat history with Core Data
- **Chunk Management**: Intelligent content continuation without overlap

## Architecture

### Core Components

- **SwiftUI Views**: Modern declarative UI with native iOS performance
- **Streaming API**: Real-time text generation using Google's Gemini 2.0 Flash API
- **Voice Recognition**: Speech framework integration for voice input
- **Secure Storage**: Keychain-based API key management

### Key Files

- `ChatView.swift` - Main conversation interface with inverted LazyVStack
- `GeminiAPIService.swift` - API integration with streaming support
- `ChunkManager.swift` - Conversation continuity management
- `VoiceService.swift` - Speech recognition implementation
- `ConversationManager.swift` - State management for chat history

## Development Setup

### Prerequisites

- Xcode 15.0+
- iOS 16.0+
- Google Gemini API key from https://makersuite.google.com/app/apikey

### Installation

1. Clone the repository
2. Open `DoomscrollGPT.xcodeproj` in Xcode
3. Configure your API key in Settings
4. Build and run on simulator or device

### Configuration

Add your Google Gemini API key through the app's Settings page or directly in the keychain:

```swift
try KeychainHelper.shared.saveAPIKey("your-gemini-api-key-here")
```

## Usage

1. **First Launch**: Complete the 2-step onboarding
2. **Start Chatting**: Type or use voice input to begin conversations
3. **Infinite Scroll**: Scroll down to automatically generate more content
4. **Voice Mode**: Tap the microphone icon for voice input
5. **History**: Access previous conversations through the history icon

## API Integration

The app uses Google's Gemini 2.5 Flash-Lite API:

- Base URL: `https://generativelanguage.googleapis.com/v1beta`
- Model: `gemini-2.5-flash-lite`
- Streaming: Enabled for real-time responses
- Context Window: 1 million tokens with intelligent summarization
- Performance: 1.5x faster than 2.0 Flash at lower cost

## Privacy & Security

- API keys stored securely in iOS Keychain
- Voice recognition with user consent
- No data collection beyond necessary app functionality
- Conversations stored locally on device

## Subscription Model

- **Free**: 50 total scrolls before signup
- **Signed-in Free**: 300 daily scrolls
- **Premium**: $5/month for unlimited scrolling

## License

This project is for educational and development purposes. Please respect Google's API terms of service.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Follow SwiftLint rules (`.swiftlint.yml`)
4. Submit a pull request

## Support

For issues or questions, please create an issue in the GitHub repository.