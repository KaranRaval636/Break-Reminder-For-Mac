import SwiftUI

public struct BreakScreenView: View {
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var appSettings: AppSettings
    
    private let tips: [String] = [
        "Look away from your screen and focus on something 20 feet away.",
        "Roll your shoulders back and relax your neck muscles.",
        "Take a slow, deep breath in... and exhale fully.",
        "Stand up, stretch your legs, and grab a fresh glass of water.",
        "Close your eyes for 30 seconds and let them completely rest.",
        "Rest your hands and shake out any wrist tension."
    ]
    
    @State private var tipIndex: Int = 0
    @State private var tipTimer: Timer?
    @State private var pulseScale: CGFloat = 1.0
    
    public init(timerManager: TimerManager, appSettings: AppSettings = .shared) {
        self.timerManager = timerManager
        self.appSettings = appSettings
    }
    
    public var body: some View {
        ZStack {
            WellnessBackground()
            
            VStack(spacing: 36) {
                Spacer()
                
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.teal, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(.bottom, 6)
                    
                    Text("Time to take a break!")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(timerManager.isLongBreak ? "You've earned a long break to recharge." : "You've earned a moment to recharge.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.75))
                }
                
                // Big Countdown Circle
                ZStack {
                    ProgressRingView(
                        progress: timerManager.progressFraction,
                        lineWidth: 14,
                        primaryColor: .teal,
                        secondaryColor: Color.white.opacity(0.12)
                    )
                    .frame(width: 250, height: 250)
                    
                    VStack(spacing: 4) {
                        Text(DateHelpers.formatRemainingTime(timerManager.remainingSeconds))
                            .font(.system(size: 54, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Text(timerManager.isLongBreak ? "LONG BREAK" : "SHORT BREAK")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(2)
                            .foregroundColor(.teal)
                    }
                }
                .scaleEffect(pulseScale)
                
                // Rotating Wellness Tip
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.cyan)
                        Text(tips[tipIndex])
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                    )
                }
                .frame(maxWidth: 550)
                .animation(.easeInOut(duration: 0.5), value: tipIndex)
                
                Spacer()
                
                // Bottom Interactive Controls
                HStack(spacing: 20) {
                    // Snooze Button
                    if appSettings.allowSnooze {
                        Button(action: {
                            timerManager.snoozeBreak()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "alarm.waves.left.and.right")
                                Text("Snooze (\(appSettings.snoozeDurationMinutes)m)")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.15))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Skip Break Button
                    Button(action: {
                        timerManager.skipBreak()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "forward.end.fill")
                            Text("Skip Break")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.25))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // End Break Early
                    Button(action: {
                        timerManager.completeBreakEarly()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Finish Break")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.teal)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 50)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            startTipRotation()
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                pulseScale = 1.03
            }
        }
        .onDisappear {
            stopTipRotation()
        }
    }
    
    private func startTipRotation() {
        tipIndex = Int.random(in: 0..<tips.count)
        tipTimer = Timer.scheduledTimer(withTimeInterval: 12, repeats: true) { _ in
            withAnimation {
                tipIndex = (tipIndex + 1) % tips.count
            }
        }
    }
    
    private func stopTipRotation() {
        tipTimer?.invalidate()
        tipTimer = nil
    }
}
