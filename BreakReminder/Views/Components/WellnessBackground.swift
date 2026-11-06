import SwiftUI

public struct WellnessBackground: View {
    @State private var animateGradient = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Base backdrop
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            // Subtle ambient glowing gradient blobs
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.15, green: 0.35, blue: 0.65).opacity(0.55),
                    Color(red: 0.08, green: 0.18, blue: 0.35).opacity(0.3),
                    Color.clear
                ]),
                center: animateGradient ? .topLeading : .bottomTrailing,
                startRadius: 80,
                endRadius: 750
            )
            .ignoresSafeArea()
            
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.5, blue: 0.45).opacity(0.45),
                    Color(red: 0.05, green: 0.25, blue: 0.3).opacity(0.2),
                    Color.clear
                ]),
                center: animateGradient ? .bottomTrailing : .topLeading,
                startRadius: 100,
                endRadius: 800
            )
            .ignoresSafeArea()
            
            // Ultra-thin visual blur material
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.65)
                .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}
