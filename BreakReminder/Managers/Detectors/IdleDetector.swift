import Foundation
import CoreGraphics

public protocol IdleTimeProvider: AnyObject {
    func systemIdleSeconds() -> TimeInterval
}

public final class SystemIdleTimeProvider: IdleTimeProvider {
    public init() {}
    
    public func systemIdleSeconds() -> TimeInterval {
        // Non-intrusive query of system session idle timer (seconds since last user mouse/keyboard input)
        let anyEvent = CGEventType(rawValue: ~0)!
        return CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyEvent)
    }
}

public final class IdleDetector: SmartPauseDetector {
    public let name = "System Idle Detector"
    private let settings: AppSettings
    private let idleProvider: IdleTimeProvider
    
    public var isEnabled: Bool {
        settings.smartPauseEnabled && settings.smartPauseIdleEnabled
    }
    
    public init(settings: AppSettings = .shared, idleProvider: IdleTimeProvider = SystemIdleTimeProvider()) {
        self.settings = settings
        self.idleProvider = idleProvider
    }
    
    public func checkPauseCondition() -> PauseReason? {
        guard isEnabled else { return nil }
        
        let idleSecs = idleProvider.systemIdleSeconds()
        let threshold = TimeInterval(settings.smartPauseIdleThresholdSeconds)
        
        if idleSecs >= threshold {
            let mins = Int(idleSecs / 60)
            let detail = mins > 0 ? "Inactive for \(mins)m" : "Inactive for \(Int(idleSecs))s"
            return PauseReason(
                type: .idle,
                title: "Away from Mac",
                detail: detail,
                systemImage: "figure.walk"
            )
        }
        return nil
    }
    
    public func currentDiagnostic() -> DetectorDiagnostic {
        let idleSecs = idleProvider.systemIdleSeconds()
        let condition = checkPauseCondition()
        return DetectorDiagnostic(
            name: name,
            isEnabled: isEnabled,
            isTriggered: condition != nil,
            details: "Current idle time: \(Int(idleSecs))s (threshold: \(settings.smartPauseIdleThresholdSeconds)s)"
        )
    }
}
