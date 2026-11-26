import AppKit

public protocol RecordingInspector: AnyObject {
    func isScreenRecordingActive() -> (isRecording: Bool, appName: String)
}

public final class DefaultRecordingInspector: RecordingInspector {
    private let recordingBundleIds: [String: String] = [
        "com.obsproject.obs-studio": "OBS Studio",
        "net.telestream.screenflow": "ScreenFlow",
        "com.loom.desktop": "Loom",
        "pl.maketheweb.cleanshotx": "CleanShot X"
    ]
    
    public init() {}
    
    public func isScreenRecordingActive() -> (isRecording: Bool, appName: String) {
        let running = NSWorkspace.shared.runningApplications
        for app in running {
            guard let bundleId = app.bundleIdentifier else { continue }
            if let name = recordingBundleIds[bundleId] {
                // If it's active / unhidden
                if !app.isHidden {
                    return (true, name)
                }
            }
        }
        return (false, "")
    }
}

public final class ScreenRecordingDetector: SmartPauseDetector {
    public let name = "Screen Recording Detector"
    private let settings: AppSettings
    private let inspector: RecordingInspector
    
    public var isEnabled: Bool {
        settings.smartPauseEnabled && settings.smartPauseRecordingEnabled
    }
    
    public init(settings: AppSettings = .shared, inspector: RecordingInspector = DefaultRecordingInspector()) {
        self.settings = settings
        self.inspector = inspector
    }
    
    public func checkPauseCondition() -> PauseReason? {
        guard isEnabled else { return nil }
        let (isRecording, appName) = inspector.isScreenRecordingActive()
        if isRecording {
            return PauseReason(
                type: .screenRecording,
                title: "Screen Recording / Broadcast",
                detail: "\(appName) is capturing screen",
                systemImage: "record.circle"
            )
        }
        return nil
    }
    
    public func currentDiagnostic() -> DetectorDiagnostic {
        let (isRecording, appName) = inspector.isScreenRecordingActive()
        return DetectorDiagnostic(
            name: name,
            isEnabled: isEnabled,
            isTriggered: isRecording,
            details: isRecording ? "Active recording in \(appName)" : "No screen capture software active"
        )
    }
}
