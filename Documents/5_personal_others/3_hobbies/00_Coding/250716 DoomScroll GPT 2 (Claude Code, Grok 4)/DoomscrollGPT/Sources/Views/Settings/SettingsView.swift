import SwiftUI

struct SettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject var subscriptionManager: SubscriptionManager
  @State private var showAPIKeyInput = false
  @State private var apiKey = ""
  @State private var showUpgradeSheet = false
  
  var body: some View {
    NavigationView {
      ZStack {
        Color.black
          .ignoresSafeArea()
        
        VStack(spacing: 0) {
          ProfileSection()
          
          List {
            Section {
              SubscriptionStatusRow()
              
              if subscriptionManager.subscription.tier != .premium {
                Button(action: { showUpgradeSheet = true }) {
                  HStack {
                    Image(systemName: "star.fill")
                      .foregroundColor(.yellow)
                    Text("Upgrade to Premium")
                      .foregroundColor(.white)
                    Spacer()
                    Text("$5/month")
                      .foregroundColor(.white.opacity(0.6))
                  }
                }
              }
            }
            .listRowBackground(Color.white.opacity(0.1))
            
            Section {
              Button(action: { showAPIKeyInput = true }) {
                HStack {
                  Image(systemName: "key.fill")
                    .foregroundColor(.white)
                  Text("Configure API Key")
                    .foregroundColor(.white)
                  Spacer()
                  Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.5))
                }
              }
            }
            .listRowBackground(Color.white.opacity(0.1))
            
            Section {
              Button(action: signOut) {
                HStack {
                  Image(systemName: "arrow.right.square")
                    .foregroundColor(.red)
                  Text("Sign Out")
                    .foregroundColor(.red)
                }
              }
            }
            .listRowBackground(Color.white.opacity(0.1))
          }
          .scrollContentBackground(.hidden)
          .background(Color.black)
        }
      }
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            dismiss()
          }
          .foregroundColor(.white)
        }
      }
      .sheet(isPresented: $showAPIKeyInput) {
        APIKeyInputView(apiKey: $apiKey)
      }
      .sheet(isPresented: $showUpgradeSheet) {
        UpgradeView()
      }
    }
  }
  
  private func signOut() {
    do {
      try KeychainHelper.shared.deleteAPIKey()
      subscriptionManager.subscription = UserSubscription()
      dismiss()
    } catch {
      print("Error signing out: \(error)")
    }
  }
}

struct ProfileSection: View {
  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "person.circle.fill")
        .font(.system(size: 80))
        .foregroundColor(.white)
      
      Text("User")
        .font(.title2)
        .fontWeight(.semibold)
        .foregroundColor(.white)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 32)
    .background(Color.black)
  }
}

struct SubscriptionStatusRow: View {
  @EnvironmentObject var subscriptionManager: SubscriptionManager
  
  var body: some View {
    HStack {
      Image(systemName: "creditcard.fill")
        .foregroundColor(.white)
      
      VStack(alignment: .leading, spacing: 4) {
        Text("Subscription")
          .foregroundColor(.white)
        
        Text(subscriptionTierText)
          .font(.caption)
          .foregroundColor(.white.opacity(0.6))
      }
      
      Spacer()
      
      if let remaining = subscriptionManager.getRemainingScrollsText() {
        Text(remaining)
          .font(.caption)
          .foregroundColor(.white.opacity(0.6))
      }
    }
  }
  
  private var subscriptionTierText: String {
    switch subscriptionManager.subscription.tier {
    case .free:
      return "Free Tier"
    case .signedInFree:
      return "Signed In (Free)"
    case .premium:
      return "Premium"
    }
  }
}

struct APIKeyInputView: View {
  @Binding var apiKey: String
  @Environment(\.dismiss) private var dismiss
  @State private var showError = false
  @State private var errorMessage = ""
  
  var body: some View {
    NavigationView {
      ZStack {
        Color.black
          .ignoresSafeArea()
        
        VStack(spacing: 24) {
          Text("Enter your Google Gemini API Key")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
          
          Text("Your API key is stored securely in the keychain and never shared.")
            .font(.body)
            .foregroundColor(.white.opacity(0.7))
            .multilineTextAlignment(.center)
          
          SecureField("API Key", text: $apiKey)
            .textFieldStyle(PlainTextFieldStyle())
            .foregroundColor(.white)
            .padding()
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                  RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            )
          
          Button(action: saveAPIKey) {
            Text("Save API Key")
              .font(.headline)
              .foregroundColor(.black)
              .frame(maxWidth: .infinity)
              .padding()
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(Color.white)
              )
          }
          .disabled(apiKey.isEmpty)
          .opacity(apiKey.isEmpty ? 0.5 : 1.0)
          
          Spacer()
        }
        .padding()
      }
      .navigationTitle("API Key")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") {
            dismiss()
          }
          .foregroundColor(.white)
        }
      }
      .alert("Error", isPresented: $showError) {
        Button("OK") { }
      } message: {
        Text(errorMessage)
      }
    }
  }
  
  private func saveAPIKey() {
    do {
      try KeychainHelper.shared.saveAPIKey(apiKey)
      dismiss()
    } catch {
      errorMessage = error.localizedDescription
      showError = true
    }
  }
}

struct UpgradeView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject var subscriptionManager: SubscriptionManager
  
  var body: some View {
    NavigationView {
      ZStack {
        Color.black
          .ignoresSafeArea()
        
        VStack(spacing: 32) {
          VStack(spacing: 16) {
            Image(systemName: "star.fill")
              .font(.system(size: 60))
              .foregroundColor(.yellow)
            
            Text("Upgrade to Premium")
              .font(.largeTitle)
              .fontWeight(.bold)
              .foregroundColor(.white)
            
            Text("Unlimited scrolling and conversations")
              .font(.title3)
              .foregroundColor(.white.opacity(0.8))
          }
          
          VStack(spacing: 16) {
            FeatureRow(icon: "infinity", text: "Unlimited scrolls")
            FeatureRow(icon: "bubble.left.and.bubble.right", text: "Unlimited conversations")
            FeatureRow(icon: "mic.fill", text: "Enhanced voice features")
            FeatureRow(icon: "heart.fill", text: "Support development")
          }
          
          Spacer()
          
          VStack(spacing: 16) {
            Button(action: upgradeToPremium) {
              Text("Upgrade for $5/month")
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                  RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                )
            }
            
            Button(action: { subscriptionManager.upgradeToSignedInFree() }) {
              Text("Sign up for free (300 daily scrolls)")
                .font(.body)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                  RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white, lineWidth: 1)
                )
            }
          }
        }
        .padding()
      }
      .navigationTitle("Upgrade")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Cancel") {
            dismiss()
          }
          .foregroundColor(.white)
        }
      }
    }
  }
  
  private func upgradeToPremium() {
    let expirationDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    subscriptionManager.upgradeToPremium(expirationDate: expirationDate)
    dismiss()
  }
}

struct FeatureRow: View {
  let icon: String
  let text: String
  
  var body: some View {
    HStack {
      Image(systemName: icon)
        .font(.system(size: 20))
        .foregroundColor(.yellow)
        .frame(width: 30)
      
      Text(text)
        .font(.body)
        .foregroundColor(.white)
      
      Spacer()
    }
  }
}

#Preview {
  SettingsView()
    .environmentObject(SubscriptionManager())
}