import AppKit

public protocol MeetingInspector: AnyObject {
    func detectActiveMeeting() -> (isMeeting: Bool, appName: String)
}

public final class DefaultMeetingInspector: MeetingInspector {
    private let knownMeetingBundleIds: [String: String] = [
        "us.zoom.xos": "Zoom",
        "com.microsoft.teams": "Microsoft Teams",
        "com.microsoft.teams2": "Microsoft Teams",
        "com.cisco.webexmeetingsapp": "Webex",
        "com.cisco.webex.Cisco-WebEx-Start": "Webex",
        "com.apple.FaceTime": "FaceTime",
        "com.skype.skype": "Skype",
        "com.tencent.meeting": "Tencent Meeting"
    ]
    
    public init() {}
    
    public func detectActiveMeeting() -> (isMeeting: Bool, appName: String) {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            return (false, "")
        }
        
        let bundleId = frontApp.bundleIdentifier ?? ""
        if let friendlyName = knownMeetingBundleIds[bundleId] {
            return (true, friendlyName)
        }
        
        // Also check window titles of browser apps if frontmost (e.g. Google Meet, Whereby)
        let name = frontApp.localizedName ?? ""
        if name.contains("Zoom") || name.contains("Teams") || name.contains("Webex") || name.contains("FaceTime") {
            return (true, name)
        }
        
        // Check window list for active meeting window titles
        let options = CGWindowListOption([.optionOnScreenOnly, .excludeDesktopElements])
        if let infoList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] {
            for win in infoList {
                if let winName = win[kCGWindowName as String] as? String {
                    if winName.contains("Google Meet") || winName.contains("Zoom Meeting") || winName.contains("Teams Call") {
                        let owner = win[kCGWindowOwnerName as String] as? String ?? "Browser"
                        return (true, "\(owner) (\(winName))")
                    }
                }
            }
        }
        
        return (false, "")
    }
}

public final class MeetingDetector: SmartPauseDetector {
    public let name = "Meeting & Call Detector"
    private let settings: AppSettings
    private let inspector: MeetingInspector
    
    public var isEnabled: Bool {
        settings.smartPauseEnabled && settings.smartPauseMeetingEnabled
    }
    
    public init(settings: AppSettings = .shared, inspector: MeetingInspector = DefaultMeetingInspector()) {
        self.settings = settings
        self.inspector = inspector
    }
    
    public func checkPauseCondition() -> PauseReason? {
        guard isEnabled else { return nil }
        let (isMeeting, appName) = inspector.detectActiveMeeting()
        if isMeeting {
            return PauseReason(
                type: .meeting,
                title: "Meeting in Progress",
                detail: "Active call in \(appName)",
                systemImage: "video.fill"
            )
        }
        return nil
    }
    
    public func currentDiagnostic() -> DetectorDiagnostic {
        let (isMeeting, appName) = inspector.detectActiveMeeting()
        return DetectorDiagnostic(
            name: name,
            isEnabled: isEnabled,
            isTriggered: isMeeting,
            details: isMeeting ? "Detected active meeting in \(appName)" : "No meeting applications detected"
        )
    }
}
