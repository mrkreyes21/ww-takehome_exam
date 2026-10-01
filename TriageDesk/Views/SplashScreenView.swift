import SwiftUI

struct SplashScreenView: View {
    @State private var logoScale: CGFloat = 0.25
    @State private var logoOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            Group {
                if let _ = UIImage(named: "AppLogo") {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 36, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.indigo],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 150, height: 150)
                            .shadow(color: Color.blue.opacity(0.4), radius: 24, x: 0, y: 12)
                        
                        Image(systemName: "tray.full.fill")
                            .font(.system(size: 68, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .scaleEffect(logoScale)
            .opacity(logoOpacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.6, blendDuration: 0)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
