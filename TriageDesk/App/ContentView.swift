import SwiftUI

struct ContentView: View {
    @StateObject private var reviewStore = ReviewStore()
    @State private var isShowingSplash = true
    
    var body: some View {
        ZStack {
            SubmissionListView()
                .environmentObject(reviewStore)
            
            if isShowingSplash {
                SplashScreenView()
                    .transition(
                        .asymmetric(
                            insertion: .opacity,
                            removal: .opacity.combined(with: .scale(scale: 1.06))
                        )
                    )
                    .zIndex(1)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    isShowingSplash = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
