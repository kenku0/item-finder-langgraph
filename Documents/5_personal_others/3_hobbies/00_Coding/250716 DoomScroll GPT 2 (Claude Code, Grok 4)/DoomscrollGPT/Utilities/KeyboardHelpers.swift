import SwiftUI

// MARK: - Keyboard Dismissal Extension
extension View {
  func hideKeyboard() {
    #if canImport(UIKit)
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    #endif
  }
  
  func dismissKeyboardOnTap() -> some View {
    self.onTapGesture {
      hideKeyboard()
    }
  }
}

// MARK: - Keyboard Observer
class KeyboardObserver: ObservableObject {
  @Published var isKeyboardVisible = false
  @Published var keyboardHeight: CGFloat = 0
  
  init() {
    #if canImport(UIKit)
    NotificationCenter.default.addObserver(
      forName: UIResponder.keyboardWillShowNotification,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      guard let userInfo = notification.userInfo,
            let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
        return
      }
      
      self?.isKeyboardVisible = true
      self?.keyboardHeight = keyboardFrame.height
    }
    #endif
    
    #if canImport(UIKit)
    NotificationCenter.default.addObserver(
      forName: UIResponder.keyboardWillHideNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.isKeyboardVisible = false
      self?.keyboardHeight = 0
    }
    #endif
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}