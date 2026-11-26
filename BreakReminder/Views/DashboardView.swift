import SwiftUI

public struct DashboardView: View {
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var settings: AppSettings
    @ObservedObject var statisticsManager: StatisticsManager
    
    @State private var showingCustomBreakSheet: Bool = false
    @State private var customBreakDuration: Int = 10
    
    public init(
        timerManager: TimerManager = .shared,
        settings: AppSettings = .shared,
        statisticsManager: StatisticsManager = .shared
    ) {
        self.timerManager = timerManager
        self.settings = settings
        self.statisticsManager = statisticsManager
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                // Top Header Bar
                headerBar
                
                // Hero Section: Timer Dial + Quick Actions
                timerDialCard
                
                // Screen Score & Status Row
                HStack(alignment: .top, spacing: 16) {
                    screenScoreCard
                    smartPauseStatusCard
                }
                
                // Key Daily Metrics 4-Grid
                dailyMetricsGrid
                
                // Instant Custom Break Bar
                instantBreakSection
            }
            .padding(24)
        }
    }
    
    // MARK: - Header Bar
    
    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Dashboard")
                    .font(.system(size: 26, weight: .bold))
                Text("Real-time wellness overview and break controls")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Active Profile Pill
            HStack(spacing: 6) {
                Image(systemName: settings.breakProfile.systemImage)
                    .foregroundColor(.accentColor)
                Text(settings.breakProfile.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.accentColor.opacity(0.12))
            )
        }
    }
    
    // MARK: - Timer Dial Card
    
    private var timerDialCard: some View {
        VStack(spacing: 18) {
            HStack {
                Label(statusTitle, systemImage: statusIcon)
                    .font(.headline)
                    .foregroundColor(statusColor)
                
                Spacer()
                
                if timerManager.status == .working {
                    let nextIsLong = (timerManager.completedWorkSessionsInCycle + 1) >= settings.longBreakFrequency
                    Text(nextIsLong ? "Next: Long Break (\(settings.longBreakMinutes)m)" : "Next: Short Break (\(settings.shortBreakMinutes)m)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if timerManager.status == .onBreak {
                    Text(timerManager.isLongBreak ? "Extended Recharge Period" : "Short Screen Rest")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Dial Visual
            ZStack {
                ProgressRingView(
                    progress: timerManager.progressFraction,
                    lineWidth: 16,
                    primaryColor: statusColor,
                    secondaryColor: Color.gray.opacity(0.15)
                )
                .frame(width: 220, height: 220)
                
                VStack(spacing: 4) {
                    Text(DateHelpers.formatRemainingTime(timerManager.remainingSeconds))
                        .font(.system(size: 46, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                    
                    Text(timerManager.status == .idle ? "READY TO START" : timerManager.status.displayName.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .tracking(2)
                        .foregroundColor(statusColor)
                }
            }
            .padding(.vertical, 8)
            
            // Control Action Buttons
            HStack(spacing: 12) {
                switch timerManager.status {
                case .idle:
                    Button(action: {
                        timerManager.startWorkSession()
                    }) {
                        Label("Start Focus Session", systemImage: "play.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                case .working:
                    Button(action: {
                        timerManager.pauseTimer()
                    }) {
                        Label("Pause", systemImage: "pause.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button(action: {
                        timerManager.startBreakImmediately()
                    }) {
                        Label("Take Break Now", systemImage: "cup.and.saucer.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                case .paused:
                    Button(action: {
                        timerManager.resumeTimer()
                    }) {
                        Label("Resume", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button(action: {
                        timerManager.resetTimer()
                    }) {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                case .onBreak:
                    if timerManager.canSnooze {
                        Button(action: {
                            timerManager.snoozeBreak()
                        }) {
                            Label("Snooze (\(settings.snoozeDurationMinutes)m)", systemImage: "alarm.waves.left.and.right")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                    
                    if timerManager.canSkip {
                        Button(action: {
                            timerManager.skipBreak()
                        }) {
                            Label("Skip", systemImage: "forward.end.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                    
                    Button(action: {
                        timerManager.completeBreakEarly()
                    }) {
                        Label("End Break", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
    
    // MARK: - Screen Score Card
    
    private var screenScoreCard: some View {
        let today = statisticsManager.todayRecord
        let score = ScreenScore.calculate(for: today)
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Screen Score", systemImage: "shield.checkerboard")
                    .font(.headline)
                Spacer()
                Text(score.rating)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(scoreBadgeColor(score.value).opacity(0.15))
                    .foregroundColor(scoreBadgeColor(score.value))
                    .cornerRadius(6)
            }
            
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.15), lineWidth: 8)
                        .frame(width: 64, height: 64)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(score.value) / 100.0)
                        .stroke(
                            scoreBadgeColor(score.value),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 64, height: 64)
                    
                    Text("\(score.value)")
                        .font(.system(size: 20, weight: .bold))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(score.ratingDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
    
    // MARK: - Smart Pause Status Card
    
    private var smartPauseStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Smart Pause", systemImage: "brain.head.profile")
                    .font(.headline)
                Spacer()
                if timerManager.isSmartPaused {
                    Text("Paused")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                } else {
                    Text("Active")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            
            if timerManager.isSmartPaused, let reason = timerManager.smartPauseReason {
                HStack(spacing: 8) {
                    Image(systemName: "pause.circle.fill")
                        .foregroundColor(.orange)
                    Text("Delayed by: \(reason)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            } else {
                Text("Monitoring full-screen apps, meetings, video playback and user idle state.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 10) {
                detectorBadge(title: "Idle", active: true)
                detectorBadge(title: "Apps", active: true)
                detectorBadge(title: "Meetings", active: true)
                detectorBadge(title: "Fullscreen", active: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
    
    @ViewBuilder
    private func detectorBadge(title: String, active: Bool) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(active ? Color.green : Color.secondary)
                .frame(width: 6, height: 6)
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Daily Metrics Grid
    
    private var dailyMetricsGrid: some View {
        let today = statisticsManager.todayRecord
        
        return LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatCard(
                title: "Work Time",
                value: DateHelpers.formatHoursAndMinutes(today.workTimeSeconds),
                subtitle: "Active screen time",
                systemImage: "laptopcomputer",
                tintColor: .blue
            )
            
            StatCard(
                title: "Breaks Taken",
                value: "\(today.completedBreaks)",
                subtitle: "Scheduled rest",
                systemImage: "cup.and.saucer.fill",
                tintColor: .teal
            )
            
            StatCard(
                title: "Breaks Skipped",
                value: "\(today.skippedBreaks)",
                subtitle: "Missed breaks",
                systemImage: "forward.end.fill",
                tintColor: today.skippedBreaks > 0 ? .orange : .secondary
            )
            
            StatCard(
                title: "Natural Breaks",
                value: "\(today.naturalBreaks)",
                subtitle: "Away from Mac",
                systemImage: "figure.walk",
                tintColor: .green
            )
        }
    }
    
    // MARK: - Instant Break Section
    
    private var instantBreakSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Instant Breaks")
                .font(.headline)
            
            HStack(spacing: 10) {
                instantBreakButton(title: "1m Eye Rest", icon: "eye.fill", minutes: 1)
                instantBreakButton(title: "5m Short Break", icon: "cup.and.saucer.fill", minutes: 5)
                instantBreakButton(title: "15m Recharge", icon: "battery.100.bolt", minutes: 15)
                instantBreakButton(title: "30m Deep Rest", icon: "moon.stars.fill", minutes: 30)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
    
    @ViewBuilder
    private func instantBreakButton(title: String, icon: String, minutes: Int) -> some View {
        Button(action: {
            timerManager.startBreakImmediately(durationMinutes: minutes)
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .windowBackgroundColor))
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helpers
    
    private var statusTitle: String {
        switch timerManager.status {
        case .idle: return "Ready to Begin"
        case .working: return "Focus Session in Progress"
        case .paused: return "Focus Session Paused"
        case .onBreak: return timerManager.isLongBreak ? "Long Break in Progress" : "Short Break in Progress"
        }
    }
    
    private var statusIcon: String {
        switch timerManager.status {
        case .idle: return "hourglass"
        case .working: return "laptopcomputer"
        case .paused: return "pause.fill"
        case .onBreak: return "cup.and.saucer.fill"
        }
    }
    
    private var statusColor: Color {
        switch timerManager.status {
        case .idle: return .secondary
        case .working: return .accentColor
        case .paused: return .orange
        case .onBreak: return .teal
        }
    }
    
    private func scoreBadgeColor(_ score: Int) -> Color {
        if score >= 85 { return .green }
        if score >= 70 { return .blue }
        if score >= 50 { return .orange }
        return .red
    }
}
