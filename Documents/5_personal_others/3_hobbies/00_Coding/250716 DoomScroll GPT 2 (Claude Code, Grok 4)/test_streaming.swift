#!/usr/bin/env swift

import Foundation

// Test script to verify Gemini API streaming functionality

let apiKey = "AIzaSyDGSWFjoM7c38LgaOZKj2CFf5mgAh3ezSg"
let baseURL = "https://generativelanguage.googleapis.com/v1beta"
let model = "gemini-2.5-flash-lite"

struct TestRequest: Codable {
    let contents: [Content]
    
    struct Content: Codable {
        let parts: [Part]
        let role: String
    }
    
    struct Part: Codable {
        let text: String
    }
}

// Create test request
let testRequest = TestRequest(contents: [
    TestRequest.Content(
        parts: [TestRequest.Part(text: "You are Gemini, an endlessly curious and insightful conversational partner.")],
        role: "user"
    ),
    TestRequest.Content(
        parts: [TestRequest.Part(text: "I understand. I'll be an endlessly curious and insightful conversational partner.")],
        role: "model"
    ),
    TestRequest.Content(
        parts: [TestRequest.Part(text: "Tell me about the history of computers")],
        role: "user"
    )
])

// Build URL
let endpoint = "\(baseURL)/models/\(model):streamGenerateContent?key=\(apiKey)"
guard let url = URL(string: endpoint) else {
    print("Invalid URL")
    exit(1)
}

// Create request
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.setValue("application/json", forHTTPHeaderField: "Content-Type")
request.httpBody = try! JSONEncoder().encode(testRequest)

print("🚀 Sending test request to Gemini API...")
print("📡 URL: \(endpoint)")

// Send request
let task = URLSession.shared.dataTask(with: request) { data, response, error in
    if let error = error {
        print("❌ Error: \(error)")
        exit(1)
    }
    
    if let httpResponse = response as? HTTPURLResponse {
        print("📊 HTTP Status: \(httpResponse.statusCode)")
    }
    
    if let data = data {
        print("📥 Response data (\(data.count) bytes):")
        if let responseString = String(data: data, encoding: .utf8) {
            print(responseString)
        }
    }
    
    exit(0)
}

task.resume()

// Wait for response
RunLoop.main.run(until: Date(timeIntervalSinceNow: 10))
print("⏱️ Timeout reached")
exit(1)