import SwiftUI

struct LoadingIndicatorView: View {
    @State private var animationAmount = 0.0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.primary)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animationAmount)
                    .opacity(animationAmount)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                        value: animationAmount
                    )
            }
        }
        .padding(.vertical, 20)
        .onAppear {
            animationAmount = 1.0
        }
    }
}

struct LoadingIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingIndicatorView()
            .preferredColorScheme(.dark)
    }
}