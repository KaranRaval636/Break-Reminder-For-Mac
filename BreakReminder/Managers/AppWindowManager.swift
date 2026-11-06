import AppKit
import SwiftUI

public final class AppWindowManager: ObservableObject {
    public static let shared = AppWindowManager()
    
    private var settingsWindow: NSWindow?
    private var statisticsWindow: NSWindow?
    
    public init() {}
    
    public func showSettingsWindow(timerManager: TimerManager, settings: AppSettings) {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let settingsView = SettingsView(settings: settings, timerManager: timerManager)
        let hostingController = NSHostingController(rootView: settingsView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Break Reminder Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrameAutosaveName("BreakReminder_Settings_Window")
        
        self.settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    public func showStatisticsWindow(statisticsManager: StatisticsManager) {
        if let window = statisticsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let statsView = StatisticsView(statisticsManager: statisticsManager)
        let hostingController = NSHostingController(rootView: statsView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Break Reminder Statistics"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 580, height: 460))
        window.minSize = NSSize(width: 480, height: 380)
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrameAutosaveName("BreakReminder_Statistics_Window")
        
        self.statisticsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
