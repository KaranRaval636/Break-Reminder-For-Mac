import SwiftUI

public struct ProgressRingView: View {
    public let progress: Double // 0.0 to 1.0
    public let lineWidth: CGFloat
    public let primaryColor: Color
    public let secondaryColor: Color
    
    public init(
        progress: Double,
        lineWidth: CGFloat = 12,
        primaryColor: Color = Color.teal,
        secondaryColor: Color = Color.white.opacity(0.12)
    ) {
        self.progress = max(0.0, min(1.0, progress))
        self.lineWidth = lineWidth
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
    }
    
    public var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(secondaryColor, lineWidth: lineWidth)
            
            // Progress arc
            Circle()
                .trim(from: 0.0, to: CGFloat(progress))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [primaryColor.opacity(0.8), primaryColor, Color.cyan]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.3), value: progress)
        }
    }
}
