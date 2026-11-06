import SwiftUI

public struct MenuBarView: View {
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var settings: AppSettings
    @ObservedObject var statisticsManager: StatisticsManager
    
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
        VStack(alignment: .leading, spacing: 14) {
            // Header: App title and status badge
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "hourglass.badge.eye")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.accentColor)
                    Text("Break Reminder")
                        .font(.system(size: 13, weight: .bold))
                }
                
                Spacer()
                
                statusBadge
            }
            
            Divider()
            
            // Countdown Display Area
            VStack(alignment: .center, spacing: 6) {
                Text(DateHelpers.formatRemainingTime(timerManager.remainingSeconds))
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(statusColor)
                    .frame(maxWidth: .infinity)
                
                Text(sessionSubtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                
                if timerManager.status != .idle {
                    ProgressView(value: timerManager.progressFraction)
                        .progressViewStyle(.linear)
                        .tint(statusColor)
                        .padding(.top, 4)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
            )
            
            // Primary Controls
            VStack(spacing: 8) {
                switch timerManager.status {
                case .idle:
                    Button(action: {
                        timerManager.startWorkSession()
                    }) {
                        Label("Start Work Session", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    
                case .working:
                    HStack(spacing: 8) {
                        Button(action: {
                            timerManager.pauseTimer()
                        }) {
                            Label("Pause", systemImage: "pause.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            timerManager.startBreakImmediately()
                        }) {
                            Label("Break Now", systemImage: "cup.and.saucer.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    Button(action: {
                        timerManager.resetTimer()
                    }) {
                        Label("Reset Timer", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .font(.caption)
                    
                case .paused:
                    HStack(spacing: 8) {
                        Button(action: {
                            timerManager.resumeTimer()
                        }) {
                            Label("Resume", systemImage: "play.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button(action: {
                            timerManager.resetTimer()
                        }) {
                            Label("Reset", systemImage: "arrow.counterclockwise")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                case .onBreak:
                    VStack(spacing: 6) {
                        HStack(spacing: 8) {
                            if settings.allowSnooze {
                                Button(action: {
                                    timerManager.snoozeBreak()
                                }) {
                                    Label("Snooze (\(settings.snoozeDurationMinutes)m)", systemImage: "alarm")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                            }
                            
                            Button(action: {
                                timerManager.skipBreak()
                            }) {
                                Label("Skip Break", systemImage: "forward.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Button(action: {
                            timerManager.completeBreakEarly()
                        }) {
                            Label("End Break Early", systemImage: "checkmark.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            
            Divider()
            
            // Secondary Navigation Actions
            VStack(alignment: .leading, spacing: 6) {
                Button(action: {
                    AppWindowManager.shared.showStatisticsWindow(statisticsManager: statisticsManager)
                }) {
                    Label("View Statistics", systemImage: "chart.bar.xaxis")
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    AppWindowManager.shared.showSettingsWindow(timerManager: timerManager, settings: settings)
                }) {
                    Label("Preferences...", systemImage: "gearshape")
                }
                .buttonStyle(.plain)
                
                Divider()
                
                Button(role: .destructive, action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Label("Quit Break Reminder", systemImage: "power")
                }
                .buttonStyle(.plain)
            }
            .font(.system(size: 12))
        }
        .padding(14)
        .frame(width: 290)
    }
    
    // MARK: - Computed Subviews & Colors
    
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)
            Text(timerManager.status.displayName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(statusColor.opacity(0.15))
        )
    }
    
    private var statusColor: Color {
        switch timerManager.status {
        case .idle:
            return .secondary
        case .working:
            return .green
        case .paused:
            return .orange
        case .onBreak:
            return .teal
        }
    }
    
    private var sessionSubtitle: String {
        switch timerManager.status {
        case .idle:
            return "Ready to begin work"
        case .working:
            let nextIndex = timerManager.completedWorkSessionsInCycle + 1
            return "Session \(nextIndex) of \(settings.longBreakFrequency) before long break"
        case .paused:
            return "Paused"
        case .onBreak:
            return timerManager.isLongBreak ? "Long restorative break" : "Short refresh break"
        }
    }
}
