import SwiftUI

public struct DashboardView: View {
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
        VStack(spacing: 20) {
            // Main timer card
            VStack(spacing: 12) {
                HStack {
                    Label(timerManager.status.displayName, systemImage: "clock")
                        .font(.headline)
                    Spacer()
                    Text("Target: \(settings.workIntervalMinutes)m work / \(settings.shortBreakMinutes)m break")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(DateHelpers.formatRemainingTime(timerManager.remainingSeconds))
                    .font(.system(size: 64, weight: .bold, design: .monospaced))
                    .foregroundColor(.accentColor)
                
                ProgressView(value: timerManager.progressFraction)
                    .progressViewStyle(.linear)
                
                HStack(spacing: 14) {
                    if timerManager.status == .idle {
                        Button("Start Work Session") {
                            timerManager.startWorkSession()
                        }
                        .buttonStyle(.borderedProminent)
                    } else if timerManager.status == .working {
                        Button("Pause") {
                            timerManager.pauseTimer()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Take Break Now") {
                            timerManager.startBreakImmediately()
                        }
                        .buttonStyle(.borderedProminent)
                    } else if timerManager.status == .paused {
                        Button("Resume") {
                            timerManager.resumeTimer()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Reset") {
                            timerManager.resetTimer()
                        }
                        .buttonStyle(.bordered)
                    } else if timerManager.status == .onBreak {
                        Button("Skip Break") {
                            timerManager.skipBreak()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("End Break Early") {
                            timerManager.completeBreakEarly()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            
            // Statistics overview
            let stats = statisticsManager.aggregate
            HStack(spacing: 12) {
                StatCard(
                    title: "Today's Sessions",
                    value: "\(stats.totalCompletedWorkSessions)",
                    subtitle: "Completed",
                    systemImage: "checkmark.circle",
                    tintColor: .blue
                )
                StatCard(
                    title: "Breaks Taken",
                    value: "\(stats.totalCompletedBreaks)",
                    subtitle: "Rest periods",
                    systemImage: "cup.and.saucer",
                    tintColor: .teal
                )
            }
        }
        .padding(24)
        .frame(minWidth: 440, minHeight: 340)
    }
}
