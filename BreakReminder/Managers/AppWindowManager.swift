import AppKit
import SwiftUI

public final class AppWindowManager: ObservableObject {
    public static let shared = AppWindowManager()
    
    private var mainWindow: NSWindow?
    
    public init() {}
    
    public func showMainWindow(
        section: NavigationSection = .dashboard,
        timerManager: TimerManager = .shared,
        settings: AppSettings = .shared,
        statisticsManager: StatisticsManager = .shared
    ) {
        if let window = mainWindow {
            // Re-host if section changed or update content
            let mainView = MainWindowView(
                settings: settings,
                timerManager: timerManager,
                statisticsManager: statisticsManager,
                initialSection: section
            )
            window.contentViewController = NSHostingController(rootView: mainView)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let mainView = MainWindowView(
            settings: settings,
            timerManager: timerManager,
            statisticsManager: statisticsManager,
            initialSection: section
        )
        let hostingController = NSHostingController(rootView: mainView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Break Reminder"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.setContentSize(NSSize(width: 960, height: 640))
        window.minSize = NSSize(width: 820, height: 520)
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrameAutosaveName("BreakReminder_Main_Window")
        
        self.mainWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    public func showSettingsWindow(timerManager: TimerManager = .shared, settings: AppSettings = .shared) {
        showMainWindow(section: .screenBreaks, timerManager: timerManager, settings: settings)
    }
    
    public func showStatisticsWindow(statisticsManager: StatisticsManager = .shared) {
        showMainWindow(section: .statistics, statisticsManager: statisticsManager)
    }
}
