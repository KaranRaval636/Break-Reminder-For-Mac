import SwiftUI

@main
struct BreakReminderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var timerManager = TimerManager.shared
    @StateObject private var settings = AppSettings.shared
    @StateObject private var statisticsManager = StatisticsManager.shared
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarView(
                timerManager: timerManager,
                settings: settings,
                statisticsManager: statisticsManager
            )
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)
        
        Settings {
            SettingsView(settings: settings, timerManager: timerManager)
        }
    }
    
    @ViewBuilder
    private var menuBarLabel: some View {
        HStack(spacing: 4) {
            Image(systemName: menuBarIcon)
            if timerManager.status != .idle {
                Text(DateHelpers.formatRemainingTime(timerManager.remainingSeconds))
                    .monospacedDigit()
            }
        }
    }
    
    private var menuBarIcon: String {
        switch timerManager.status {
        case .idle:
            return "hourglass"
        case .working:
            return "laptopcomputer"
        case .paused:
            return "pause.fill"
        case .onBreak:
            return "cup.and.saucer.fill"
        }
    }
}
