import AppKit

public protocol FullscreenInspector: AnyObject {
    func isFrontmostAppFullscreen() -> (isFullscreen: Bool, appName: String)
}

public final class DefaultFullscreenInspector: FullscreenInspector {
    public init() {}
    
    public func isFrontmostAppFullscreen() -> (isFullscreen: Bool, appName: String) {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            return (false, "")
        }
        
        let appName = frontApp.localizedName ?? "Application"
        
        // 1. Quick check: On macOS, full screen apps hide the menu bar on their display,
        // making screen.visibleFrame equal to screen.frame.
        if let mainScreen = NSScreen.main {
            if mainScreen.visibleFrame == mainScreen.frame {
                // Ignore Finder or BreakReminder itself
                if frontApp.bundleIdentifier != "com.apple.finder" && frontApp.bundleIdentifier != Bundle.main.bundleIdentifier {
                    return (true, appName)
                }
            }
        }
        
        // 2. Quartz Window list check: Check frontmost app's windows for full screen dimensions
        let options = CGWindowListOption([.optionOnScreenOnly, .excludeDesktopElements])
        guard let infoList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return (false, appName)
        }
        
        let frontPID = frontApp.processIdentifier
        for windowInfo in infoList {
            guard let pid = windowInfo[kCGWindowOwnerPID as String] as? pid_t, pid == frontPID else { continue }
            guard let boundsDict = windowInfo[kCGWindowBounds as String] as? [String: CGFloat],
                  let width = boundsDict["Width"],
                  let height = boundsDict["Height"] else { continue }
            
            // Check if window bounds match any connected screen size
            for screen in NSScreen.screens {
                if abs(screen.frame.width - width) < 2 && abs(screen.frame.height - height) < 2 {
                    return (true, appName)
                }
            }
        }
        
        return (false, appName)
    }
}

public final class FullscreenDetector: SmartPauseDetector {
    public let name = "Full-Screen Detector"
    private let settings: AppSettings
    private let inspector: FullscreenInspector
    
    public var isEnabled: Bool {
        settings.smartPauseEnabled && settings.smartPauseFullscreenEnabled
    }
    
    public init(settings: AppSettings = .shared, inspector: FullscreenInspector = DefaultFullscreenInspector()) {
        self.settings = settings
        self.inspector = inspector
    }
    
    public func checkPauseCondition() -> PauseReason? {
        guard isEnabled else { return nil }
        let (isFullscreen, appName) = inspector.isFrontmostAppFullscreen()
        if isFullscreen {
            return PauseReason(
                type: .fullscreen,
                title: "Full-Screen Application",
                detail: "\(appName) is in full-screen",
                systemImage: "arrow.up.left.and.arrow.down.right"
            )
        }
        return nil
    }
    
    public func currentDiagnostic() -> DetectorDiagnostic {
        let (isFullscreen, appName) = inspector.isFrontmostAppFullscreen()
        return DetectorDiagnostic(
            name: name,
            isEnabled: isEnabled,
            isTriggered: isFullscreen,
            details: isFullscreen ? "Full-screen mode active in \(appName)" : "Standard windowed mode"
        )
    }
}
