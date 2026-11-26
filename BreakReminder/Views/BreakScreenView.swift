import SwiftUI

public struct BreakScreenView: View {
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var appSettings: AppSettings
    
    @State private var tipIndex: Int = 0
    @State private var tipTimer: Timer?
    @State private var isBreathingMode: Bool = false
    
    // Breathing Cycle: Inhale (4s), Hold (4s), Exhale (4s)
    @State private var breathPhase: String = "Inhale"
    @State private var breathScale: CGFloat = 0.8
    @State private var breathTimer: Timer?
    
    public init(timerManager: TimerManager, appSettings: AppSettings = .shared) {
        self.timerManager = timerManager
        self.appSettings = appSettings
    }
    
    public var body: some View {
        ZStack {
            WellnessBackground(style: appSettings.backgroundStyle)
            
            VStack(spacing: 32) {
                Spacer()
                
                // Header with custom title & subtitle
                VStack(spacing: 8) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.teal, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(.bottom, 4)
                    
                    Text(titleText)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(textColor)
                    
                    Text(subtitleText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(textColor.opacity(0.8))
                }
                
                // Center Display: Countdown Ring OR Breathing Exercise
                if isBreathingMode && appSettings.breathingGuideEnabled {
                    breathingGuideCard
                } else {
                    countdownDialCard
                }
                
                // Mode Toggle Pill
                if appSettings.breathingGuideEnabled {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isBreathingMode.toggle()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: isBreathingMode ? "timer" : "wind")
                            Text(isBreathingMode ? "Show Timer Dial" : "Guided Breathing (4-4-4)")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(textColor.opacity(0.9))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.12))
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                // Rotating Wellness Tip
                if !availableTips.isEmpty {
                    wellnessTipCard
                }
                
                Spacer()
                
                // Bottom Interactive Controls (Snooze, Skip, End Break)
                bottomControlsBar
            }
            .padding(.bottom, 40)
        }
        .onAppear {
            startTipTimer()
            startBreathingCycle()
        }
        .onDisappear {
            stopTimers()
        }
    }
    
    // MARK: - Central Countdown Dial
    
    private var countdownDialCard: some View {
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
                    .foregroundColor(textColor)
                
                Text(timerManager.isLongBreak ? "LONG BREAK" : "SHORT BREAK")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2)
                    .foregroundColor(.teal)
            }
        }
    }
    
    // MARK: - Mindful Breathing Exercise
    
    private var breathingGuideCard: some View {
        ZStack {
            Circle()
                .stroke(Color.teal.opacity(0.2), lineWidth: 10)
                .frame(width: 250, height: 250)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.teal.opacity(0.4), Color.cyan.opacity(0.1)],
                        center: .center,
                        startRadius: 20,
                        endRadius: 120
                    )
                )
                .frame(width: 230, height: 230)
                .scaleEffect(breathScale)
            
            VStack(spacing: 6) {
                Text(breathPhase)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
                
                Text(DateHelpers.formatRemainingTime(timerManager.remainingSeconds))
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(textColor.opacity(0.7))
            }
        }
        .frame(height: 250)
    }
    
    // MARK: - Wellness Tip
    
    private var wellnessTipCard: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .foregroundColor(.cyan)
                Text(availableTips[tipIndex % availableTips.count])
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(textColor.opacity(0.95))
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
        .frame(maxWidth: 560)
        .animation(.easeInOut(duration: 0.5), value: tipIndex)
    }
    
    // MARK: - Bottom Controls Bar
    
    private var bottomControlsBar: some View {
        HStack(spacing: 16) {
            // Snooze Button
            if timerManager.canSnooze {
                Button(action: {
                    timerManager.snoozeBreak()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "alarm.waves.left.and.right")
                        Text(snoozeButtonTitle)
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(textColor)
                    .padding(.horizontal, 20)
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
            
            // Skip Button
            if timerManager.canSkip {
                Button(action: {
                    timerManager.skipBreak()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "forward.end.fill")
                        Text("Skip Break")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(textColor.opacity(0.85))
                    .padding(.horizontal, 20)
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
            }
            
            // End Break Early Button
            Button(action: {
                timerManager.completeBreakEarly()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("End Break Early")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(textColor)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.teal.opacity(0.4))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.teal.opacity(0.7), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Helpers
    
    private var titleText: String {
        let custom = appSettings.customBreakTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return custom.isEmpty ? "Time to take a break!" : custom
    }
    
    private var subtitleText: String {
        let custom = appSettings.customBreakSubtitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !custom.isEmpty { return custom }
        return timerManager.isLongBreak
            ? "You've earned a long break to recharge."
            : "You've earned a moment to recharge."
    }
    
    private var availableTips: [String] {
        appSettings.customTips.isEmpty ? AppSettings.defaultCustomTips : appSettings.customTips
    }
    
    private var snoozeButtonTitle: String {
        if let rem = timerManager.remainingSnoozes {
            return "Snooze (\(appSettings.snoozeDurationMinutes)m • \(rem) left)"
        }
        return "Snooze (\(appSettings.snoozeDurationMinutes)m)"
    }
    
    private var textColor: Color {
        appSettings.backgroundStyle == "light" ? .black : .white
    }
    
    private func startTipTimer() {
        tipTimer?.invalidate()
        tipTimer = Timer.scheduledTimer(withTimeInterval: 12.0, repeats: true) { _ in
            if !availableTips.isEmpty {
                tipIndex = (tipIndex + 1) % availableTips.count
            }
        }
    }
    
    private func startBreathingCycle() {
        breathTimer?.invalidate()
        var step = 0
        breathTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            step = (step + 1) % 3
            switch step {
            case 0:
                breathPhase = "Inhale"
                withAnimation(.easeInOut(duration: 4.0)) { breathScale = 1.05 }
            case 1:
                breathPhase = "Hold"
            case 2:
                breathPhase = "Exhale"
                withAnimation(.easeInOut(duration: 4.0)) { breathScale = 0.75 }
            default:
                break
            }
        }
    }
    
    private func stopTimers() {
        tipTimer?.invalidate()
        tipTimer = nil
        breathTimer?.invalidate()
        breathTimer = nil
    }
}
