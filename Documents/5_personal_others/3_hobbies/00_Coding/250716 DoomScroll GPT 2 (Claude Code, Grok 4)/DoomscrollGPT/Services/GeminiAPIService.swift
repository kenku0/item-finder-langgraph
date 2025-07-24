import Foundation

class GeminiAPIService {
  private let baseURL = "https://generativelanguage.googleapis.com/v1beta"
  private let model = "gemini-2.5-flash-lite"
  private let systemPrompt = """
You are a highly advanced AI assistant, designed to provide the most detailed, specific, and comprehensive responses possible. Your goal is to generate a continuous, in-depth stream of information.

When responding, adhere to the following principles:
1. **Maximize Detail:** Provide exhaustive and specific information on the topic. Delve deep into concepts, providing examples, data, and thorough explanations. Do not hold back on complexity or length.
2. **Continuous Generation:** Your responses will be part of a larger, automatically continued dialogue. Do not conclude your thoughts or summarize. Simply provide the next logical and detailed chunk of information as if you are writing a comprehensive document. The user will signal for you to continue.
3. **No User Interaction:** Do not ask the user questions for clarification or feedback. Assume you have all the necessary context from the conversation history and proceed with generating the most complete response possible.
4. **Authoritative Tone:** Maintain an expert, authoritative, and informative tone.
5. **Format:** Don't use **bold** or *italic* formatting only produce plain text.

Your task is to generate the next part of the response, picking up exactly where you left off, ensuring a seamless and continuous flow of detailed information.
"""
  
  private var apiKey: String? {
    KeychainHelper.shared.getAPIKey()
  }
  
  enum APIError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case networkError(String)
    case decodingError(String)
    case streamingFailed(String)
    
    var errorDescription: String? {
      switch self {
      case .missingAPIKey:
        return "API key not found. Please configure your API key."
      case .invalidURL:
        return "Invalid API URL configuration."
      case .networkError(let message):
        return "Network error: \(message)"
      case .decodingError(let message):
        return "Failed to decode response: \(message)"
      case .streamingFailed(let message):
        return "Streaming failed: \(message)"
      }
    }
  }
  
  // MARK: - Request/Response Models
  struct GenerateContentRequest: Codable {
    let contents: [Content]
    let generationConfig: GenerationConfig?
    
    struct Content: Codable {
      let parts: [Part]
      let role: String
    }
    
    struct Part: Codable {
      let text: String
    }
    
    struct GenerationConfig: Codable {
      let temperature: Double
      let maxOutputTokens: Int
      let topP: Double?
      let topK: Int?
    }
  }
  
  struct GenerateContentResponse: Codable {
    let candidates: [Candidate]
    let usageMetadata: UsageMetadata?
    
    struct Candidate: Codable {
      let content: Content
      let finishReason: String?
      let safetyRatings: [SafetyRating]?
      
      struct Content: Codable {
        let parts: [Part]
        let role: String
      }
      
      struct Part: Codable {
        let text: String
      }
    }
    
    struct SafetyRating: Codable {
      let category: String
      let probability: String
    }
    
    struct UsageMetadata: Codable {
      let promptTokenCount: Int?
      let candidatesTokenCount: Int?
      let totalTokenCount: Int?
    }
  }
  
  func streamCompletion(messages: [[String: String]]) async throws -> AsyncThrowingStream<String, Error> {
    guard let apiKey = apiKey else {
      print("❌ GeminiAPI: Missing API key")
      throw APIError.missingAPIKey
    }
    
    print("🔑 GeminiAPI: Using API key: \(apiKey.prefix(10))...")
    
    let endpoint = "\(baseURL)/models/\(model):streamGenerateContent"
    guard var urlComponents = URLComponents(string: endpoint) else {
      print("❌ GeminiAPI: Invalid URL: \(endpoint)")
      throw APIError.invalidURL
    }
    
    urlComponents.queryItems = [
      URLQueryItem(name: "key", value: apiKey)
    ]
    
    guard let url = urlComponents.url else {
      print("❌ GeminiAPI: Failed to build URL with components")
      throw APIError.invalidURL
    }
    
    print("📡 GeminiAPI: Request URL: \(url.absoluteString)")
    
    let requestBody = buildRequestBody(from: messages)
    print("📝 GeminiAPI: Request body: \(requestBody)")
    print("💬 GeminiAPI: Messages count: \(messages.count)")
    
    return AsyncThrowingStream { continuation in
      Task {
        do {
          var request = URLRequest(url: url)
          request.httpMethod = "POST"
          request.setValue("application/json", forHTTPHeaderField: "Content-Type")
          request.httpBody = try JSONEncoder().encode(requestBody)
          
          print("🚀 GeminiAPI: Sending request...")
          
          let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
          
          guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ GeminiAPI: Invalid response type")
            continuation.finish(throwing: APIError.networkError("Invalid response"))
            return
          }
          
          print("📊 GeminiAPI: HTTP Status: \(httpResponse.statusCode)")
          
          if httpResponse.statusCode != 200 {
            print("❌ GeminiAPI: HTTP Error \(httpResponse.statusCode)")
            continuation.finish(throwing: APIError.networkError("HTTP \(httpResponse.statusCode)"))
            return
          }
          
          print("✅ GeminiAPI: Starting to read stream...")
          
          var buffer = ""
          var currentObjectLines: [String] = []
          var braceCount = 0
          var inObject = false
          
          outerLoop: for try await line in asyncBytes.lines {
            print("📥 GeminiAPI: Received line: \(line)")
            buffer += line + "\n"
            
            // Skip array boundaries
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == "[{" || trimmed == "[" || trimmed == "]" || trimmed == "" {
              if trimmed == "[{" {
                inObject = true
                braceCount = 1
                currentObjectLines = ["{"]
              }
              continue
            }
            
            // If we're building an object, add this line
            if inObject {
              currentObjectLines.append(line)
              
              // Count braces in this line (simple approach)
              for char in line {
                if char == "{" { braceCount += 1 }
                else if char == "}" { braceCount -= 1 }
              }
              
              // If we've closed all braces, we have a complete object
              if braceCount == 0 {
                let objectString = currentObjectLines.joined(separator: "\n")
                
                // Remove trailing comma if present
                var cleanObject = objectString.trimmingCharacters(in: .whitespacesAndNewlines)
                if cleanObject.hasSuffix(",") {
                  cleanObject = String(cleanObject.dropLast())
                }
                
                print("🔍 GeminiAPI: Attempting to parse object")
                
                // First attempt: Try to extract text directly using regex
                // This avoids JSON parsing issues entirely
                let textPattern = #""text"\s*:\s*"([^"\\]*(\\.[^"\\]*)*)""#
                if let regex = try? NSRegularExpression(pattern: textPattern, options: []) {
                  let matches = regex.matches(in: cleanObject, options: [], range: NSRange(location: 0, length: cleanObject.utf16.count))
                  
                  for match in matches {
                    if let range = Range(match.range(at: 1), in: cleanObject) {
                      let text = String(cleanObject[range])
                      // Unescape JSON string
                      let unescaped = text
                        .replacingOccurrences(of: "\\\"", with: "\"")
                        .replacingOccurrences(of: "\\\\", with: "\\")
                        .replacingOccurrences(of: "\\/", with: "/")
                        .replacingOccurrences(of: "\\n", with: "\n")
                        .replacingOccurrences(of: "\\r", with: "\r")
                        .replacingOccurrences(of: "\\t", with: "\t")
                      
                      if !unescaped.isEmpty {
                        print("✨ GeminiAPI: Extracted text via regex: \(unescaped)")
                        continuation.yield(unescaped)
                        
                        // Reset for next object
                        inObject = false
                        currentObjectLines = []
                        braceCount = 0
                        continue outerLoop // Continue to next line
                      }
                    }
                  }
                }
                
                
                // Reset for next object
                inObject = false
                currentObjectLines = []
                braceCount = 0
              }
            } else {
              // Check if this line starts a new object
              if trimmed.hasPrefix("{") {
                inObject = true
                braceCount = 0
                currentObjectLines = [line]
                
                // Count braces in this line
                for char in line {
                  if char == "{" { braceCount += 1 }
                  else if char == "}" { braceCount -= 1 }
                }
              }
            }
          }
          
          
          print("🏁 GeminiAPI: Stream finished")
          continuation.finish()
        } catch {
          print("❌ GeminiAPI: Stream error: \(error)")
          continuation.finish(throwing: APIError.streamingFailed(error.localizedDescription))
        }
      }
    }
  }
  
  func generateResponse(for messages: [[String: String]]) async throws -> String {
    guard let apiKey = apiKey else {
      throw APIError.missingAPIKey
    }
    
    let endpoint = "\(baseURL)/models/\(model):generateContent"
    guard var urlComponents = URLComponents(string: endpoint) else {
      throw APIError.invalidURL
    }
    
    urlComponents.queryItems = [URLQueryItem(name: "key", value: apiKey)]
    
    guard let url = urlComponents.url else {
      throw APIError.invalidURL
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let requestBody = buildRequestBody(from: messages)
    request.httpBody = try JSONEncoder().encode(requestBody)
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse else {
      throw APIError.networkError("Invalid response")
    }
    
    if httpResponse.statusCode != 200 {
      let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
      throw APIError.networkError("HTTP \(httpResponse.statusCode): \(errorMessage)")
    }
    
    let apiResponse = try JSONDecoder().decode(GenerateContentResponse.self, from: data)
    
    return apiResponse.candidates.first?.content.parts.first?.text ?? ""
  }
  
  // MARK: - Helper Methods
  
  private func buildRequestBody(from messages: [[String: String]]) -> GenerateContentRequest {
    var contents: [GenerateContentRequest.Content] = []
    
    // Add system prompt as first user message
    contents.append(GenerateContentRequest.Content(
      parts: [GenerateContentRequest.Part(text: systemPrompt)],
      role: "user"
    ))
    
    // Add a model response to establish the system context
    contents.append(GenerateContentRequest.Content(
      parts: [GenerateContentRequest.Part(text: "I understand. I'll be an endlessly curious and insightful conversational partner, engaging in continuous dialogue while keeping the flow going.")],
      role: "model"
    ))
    
    // Convert all messages
    for message in messages {
      let content = message["content"] ?? ""
      let role = message["role"] ?? "user"
      
      if role == "system" {
        // Skip system messages as we already added our system prompt
        continue
      }
      
      let modelRole = convertRole(role)
      contents.append(GenerateContentRequest.Content(
        parts: [GenerateContentRequest.Part(text: content)],
        role: modelRole
      ))
    }
    
    return GenerateContentRequest(
      contents: contents,
      generationConfig: GenerateContentRequest.GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 8192,
        topP: 0.95,
        topK: 40
      )
    )
  }
  
  private func parseSSEEvent(_ event: String) -> String? {
    let lines = event.components(separatedBy: "\n")
    
    for line in lines {
      if line.hasPrefix("data: ") {
        let jsonString = String(line.dropFirst(6))
        
        // Skip special SSE messages
        if jsonString == "[DONE]" || jsonString.isEmpty {
          return nil
        }
        
        guard let jsonData = jsonString.data(using: .utf8) else { continue }
        
        do {
          let response = try JSONDecoder().decode(GenerateContentResponse.self, from: jsonData)
          if let text = response.candidates.first?.content.parts.first?.text {
            return text
          }
        } catch {
          // Skip malformed chunks
          continue
        }
      }
    }
    
    return nil
  }
  
  private func convertRole(_ role: String) -> String {
    switch role {
    case "system", "assistant":
      return "model"
    case "user":
      return "user"
    default:
      return "user"
    }
  }
  
  func createContinuationPrompt(withUserInput userInput: String? = nil) -> String {
    if let userInput = userInput, !userInput.isEmpty {
      return "Continue the thought from your last response, and also incorporate this new idea: \(userInput). Do not repeat any information you have already provided."
    } else {
      return "Continue the thought from your last response. Provide the next logical chunk of the conversation. Do not repeat any information you have already provided."
    }
  }
  
  func createSystemMessage() -> [String: String] {
    [
      "role": "system",
      "content": systemPrompt
    ]
  }
}