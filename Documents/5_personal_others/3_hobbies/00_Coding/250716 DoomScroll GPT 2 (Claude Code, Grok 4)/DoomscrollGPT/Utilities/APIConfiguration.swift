import Foundation

class APIConfiguration {
  static let shared = APIConfiguration()
  private init() {}
  
  // For development/testing - Remove before production
  private let defaultAPIKey = "AIzaSyDGSWFjoM7c38LgaOZKj2CFf5mgAh3ezSg"
  
  func setupDefaultAPIKeyIfNeeded() {
    #if DEBUG
    // Only set default API key in debug builds
    if KeychainHelper.shared.getAPIKey() == nil {
      do {
        try KeychainHelper.shared.saveAPIKey(defaultAPIKey)
        print("Default Gemini API key configured for testing")
      } catch {
        print("Failed to set default API key: \(error)")
      }
    }
    #endif
  }
  
  func clearAPIKey() {
    do {
      try KeychainHelper.shared.deleteAPIKey()
      print("API key cleared")
    } catch {
      print("Failed to clear API key: \(error)")
    }
  }
}