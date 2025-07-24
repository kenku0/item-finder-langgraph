import Foundation
import Security

class KeychainHelper {
  static let shared = KeychainHelper()
  private init() {}
  
  private let service = "com.doomscrollgpt.app"
  private let apiKeyAccount = "gemini-api-key"
  
  enum KeychainError: LocalizedError {
    case itemNotFound
    case duplicateItem
    case invalidData
    case unhandledError(status: OSStatus)
    
    var errorDescription: String? {
      switch self {
      case .itemNotFound:
        return "API key not found in keychain"
      case .duplicateItem:
        return "API key already exists in keychain"
      case .invalidData:
        return "Invalid data format"
      case .unhandledError(let status):
        return "Keychain error: \(status)"
      }
    }
  }
  
  func saveAPIKey(_ apiKey: String) throws {
    let data = apiKey.data(using: .utf8)!
    
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: apiKeyAccount,
      kSecValueData as String: data
    ]
    
    let status = SecItemAdd(query as CFDictionary, nil)
    
    if status == errSecDuplicateItem {
      try updateAPIKey(apiKey)
    } else if status != errSecSuccess {
      throw KeychainError.unhandledError(status: status)
    }
  }
  
  func getAPIKey() -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: apiKeyAccount,
      kSecMatchLimit as String: kSecMatchLimitOne,
      kSecReturnData as String: true
    ]
    
    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    
    guard status == errSecSuccess,
          let data = result as? Data,
          let apiKey = String(data: data, encoding: .utf8) else {
      return nil
    }
    
    return apiKey
  }
  
  func deleteAPIKey() throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: apiKeyAccount
    ]
    
    let status = SecItemDelete(query as CFDictionary)
    
    if status != errSecSuccess && status != errSecItemNotFound {
      throw KeychainError.unhandledError(status: status)
    }
  }
  
  private func updateAPIKey(_ apiKey: String) throws {
    let data = apiKey.data(using: .utf8)!
    
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: apiKeyAccount
    ]
    
    let attributes: [String: Any] = [
      kSecValueData as String: data
    ]
    
    let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    
    if status != errSecSuccess {
      throw KeychainError.unhandledError(status: status)
    }
  }
}