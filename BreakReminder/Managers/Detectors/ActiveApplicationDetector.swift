import AppKit

public protocol WorkspaceAppProvider: AnyObject {
    func frontmostApplication() -> NSRunningApplication?
    func runningApplications() -> [NSRunningApplication]
}

public final class DefaultWorkspaceAppProvider: WorkspaceAppProvider {
    public init() {}
    
    public func frontmostApplication() -> NSRunningApplication? {
        NSWorkspace.shared.frontmostApplication
    }
    
    public func runningApplications() -> [NSRunningApplication] {
        NSWorkspace.shared.runningApplications
    }
}

public final class ActiveApplicationDetector: SmartPauseDetector {
    public let name = "Active Application Detector"
    private let settings: AppSettings
    private let workspaceProvider: WorkspaceAppProvider
    
    public var isEnabled: Bool {
        settings.smartPauseEnabled
    }
    
    public init(settings: AppSettings = .shared, workspaceProvider: WorkspaceAppProvider = DefaultWorkspaceAppProvider()) {
        self.settings = settings
        self.workspaceProvider = workspaceProvider
    }
    
    public func checkPauseCondition() -> PauseReason? {
        // Serves as base info provider; specific pauses handled by UserFocusAppDetector and FullscreenDetector
        return nil
    }
    
    public func currentDiagnostic() -> DetectorDiagnostic {
        let app = workspaceProvider.frontmostApplication()
        let appName = app?.localizedName ?? "None"
        let bundleId = app?.bundleIdentifier ?? "Unknown"
        return DetectorDiagnostic(
            name: name,
            isEnabled: isEnabled,
            isTriggered: false,
            details: "Frontmost App: \(appName) (\(bundleId))"
        )
    }
}
