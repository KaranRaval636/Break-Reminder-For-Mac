import AppKit

public final class UserFocusAppDetector: SmartPauseDetector {
    public let name = "Focus Applications Detector"
    private let settings: AppSettings
    private let workspaceProvider: WorkspaceAppProvider
    
    public var isEnabled: Bool {
        settings.smartPauseEnabled && settings.smartPauseFocusAppsEnabled
    }
    
    public init(settings: AppSettings = .shared, workspaceProvider: WorkspaceAppProvider = DefaultWorkspaceAppProvider()) {
        self.settings = settings
        self.workspaceProvider = workspaceProvider
    }
    
    public func checkPauseCondition() -> PauseReason? {
        guard isEnabled else { return nil }
        guard let frontApp = workspaceProvider.frontmostApplication(),
              let bundleId = frontApp.bundleIdentifier else {
            return nil
        }
        
        let appName = frontApp.localizedName ?? "Application"
        
        // Match by bundle identifier or localized name
        let isExcluded = settings.excludedApps.contains { item in
            item.bundleIdentifier.caseInsensitiveCompare(bundleId) == .orderedSame ||
            item.name.caseInsensitiveCompare(appName) == .orderedSame
        }
        
        if isExcluded {
            return PauseReason(
                type: .focusApp,
                title: "Focus Application Active",
                detail: "\(appName) is in your break exclusion list",
                systemImage: "app.badge.checkmark"
            )
        }
        return nil
    }
    
    public func currentDiagnostic() -> DetectorDiagnostic {
        let frontApp = workspaceProvider.frontmostApplication()
        let appName = frontApp?.localizedName ?? "None"
        let isTriggered = checkPauseCondition() != nil
        return DetectorDiagnostic(
            name: name,
            isEnabled: isEnabled,
            isTriggered: isTriggered,
            details: isTriggered
                ? "\(appName) matches an exclusion entry (\(settings.excludedApps.count) apps configured)"
                : "\(appName) not excluded (\(settings.excludedApps.count) apps in list)"
        )
    }
}
