import SwiftUI

public struct WellnessBackground: View {
    public let style: String
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animateGradient: Bool = false
    
    public init(style: String = "aurora") {
        self.style = style
    }
    
    public var body: some View {
        ZStack {
            switch style {
            case "dark":
                darkBackground
            case "gradient":
                gradientMeshBackground
            case "light":
                lightBackground
            default: // "aurora"
                auroraBackground
            }
        }
        .onAppear {
            if !reduceMotion && style == "aurora" {
                withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                    animateGradient.toggle()
                }
            }
        }
    }
    
    // MARK: - Aurora Ambient Style
    
    private var auroraBackground: some View {
        ZStack {
            Color.black.opacity(0.88)
                .ignoresSafeArea()
            
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.12, green: 0.35, blue: 0.65).opacity(0.6),
                    Color(red: 0.05, green: 0.15, blue: 0.35).opacity(0.3),
                    Color.clear
                ]),
                center: animateGradient ? .topLeading : .bottomTrailing,
                startRadius: 80,
                endRadius: 800
            )
            .ignoresSafeArea()
            
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.08, green: 0.52, blue: 0.45).opacity(0.5),
                    Color(red: 0.04, green: 0.22, blue: 0.28).opacity(0.2),
                    Color.clear
                ]),
                center: animateGradient ? .bottomTrailing : .topLeading,
                startRadius: 100,
                endRadius: 850
            )
            .ignoresSafeArea()
            
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.6)
                .ignoresSafeArea()
        }
    }
    
    // MARK: - Gradient Mesh Style
    
    private var gradientMeshBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.12, blue: 0.28),
                    Color(red: 0.12, green: 0.24, blue: 0.40),
                    Color(red: 0.05, green: 0.18, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.5)
                .ignoresSafeArea()
        }
    }
    
    // MARK: - Deep Dark Minimalist
    
    private var darkBackground: some View {
        ZStack {
            Color(red: 0.06, green: 0.07, blue: 0.09)
                .ignoresSafeArea()
            
            RadialGradient(
                colors: [Color.cyan.opacity(0.12), Color.clear],
                center: .center,
                startRadius: 50,
                endRadius: 600
            )
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Soft Light Minimalist
    
    private var lightBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.94, green: 0.96, blue: 0.98),
                    Color(red: 0.88, green: 0.93, blue: 0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            RadialGradient(
                colors: [Color.teal.opacity(0.15), Color.clear],
                center: .center,
                startRadius: 50,
                endRadius: 500
            )
            .ignoresSafeArea()
        }
    }
}
