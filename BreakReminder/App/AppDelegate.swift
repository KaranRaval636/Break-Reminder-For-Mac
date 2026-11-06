import AppKit

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure app does not quit when windows (settings, stats) close
        NSApplication.shared.setActivationPolicy(.accessory)
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        // Save state before quitting
        TimerManager.shared.saveState()
    }
}
