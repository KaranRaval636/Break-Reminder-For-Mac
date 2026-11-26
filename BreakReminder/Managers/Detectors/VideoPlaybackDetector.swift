import AppKit

public protocol VideoPlaybackInspector: AnyObject {
    func isVideoPlaybackActive() -> (isPlaying: Bool, appName: String)
}

public final class DefaultVideoPlaybackInspector: VideoPlaybackInspector {
    private let videoAppBundleIds: [String: String] = [
        "com.apple.QuickTimePlayerX": "QuickTime Player",
        "org.videolan.vlc": "VLC Media Player",
        "com.colliderli.iina": "IINA",
        "com.apple.TV": "Apple TV",
        "tv.plex.desktop": "Plex",
        "com.firecore.infuse": "Infuse"
    ]
    
    public init() {}
    
    public func isVideoPlaybackActive() -> (isPlaying: Bool, appName: String) {
        guard let frontApp = NSWorkspace.shared.frontmostApplication,
              let bundleId = frontApp.bundleIdentifier else {
            return (false, "")
        }
        
        if let friendlyName = videoAppBundleIds[bundleId] {
            return (true, friendlyName)
        }
        return (false, "")
    }
}

public final class VideoPlaybackDetector: SmartPauseDetector {
    public let name = "Video Playback Detector"
    private let settings: AppSettings
    private let inspector: VideoPlaybackInspector
    
    public var isEnabled: Bool {
        settings.smartPauseEnabled && settings.smartPauseVideoEnabled
    }
    
    public init(settings: AppSettings = .shared, inspector: VideoPlaybackInspector = DefaultVideoPlaybackInspector()) {
        self.settings = settings
        self.inspector = inspector
    }
    
    public func checkPauseCondition() -> PauseReason? {
        guard isEnabled else { return nil }
        let (isPlaying, appName) = inspector.isVideoPlaybackActive()
        if isPlaying {
            return PauseReason(
                type: .videoPlayback,
                title: "Media Playback",
                detail: "Playing media in \(appName)",
                systemImage: "play.tv.fill"
            )
        }
        return nil
    }
    
    public func currentDiagnostic() -> DetectorDiagnostic {
        let (isPlaying, appName) = inspector.isVideoPlaybackActive()
        return DetectorDiagnostic(
            name: name,
            isEnabled: isEnabled,
            isTriggered: isPlaying,
            details: isPlaying ? "Active player: \(appName)" : "No media players frontmost"
        )
    }
}
