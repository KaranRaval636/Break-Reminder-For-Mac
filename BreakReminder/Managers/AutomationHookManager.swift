import Foundation
import Combine

public enum AutomationEvent: Equatable {
    case workSessionStarted
    case breakStarted(isLong: Bool)
    case breakEnded
    case breakSkipped
    case smartPauseActivated(reason: String)
    case smartPauseDeactivated
    
    public var notificationName: String {
        switch self {
        case .workSessionStarted:
            return "com.breakreminder.WorkSessionStarted"
        case .breakStarted(let isLong):
            return isLong ? "com.breakreminder.LongBreakStarted" : "com.breakreminder.ShortBreakStarted"
        case .breakEnded:
            return "com.breakreminder.BreakEnded"
        case .breakSkipped:
            return "com.breakreminder.BreakSkipped"
        case .smartPauseActivated:
            return "com.breakreminder.SmartPauseActivated"
        case .smartPauseDeactivated:
            return "com.breakreminder.SmartPauseDeactivated"
        }
    }
}

public protocol AutomationHookManaging: AnyObject {
    func handleEvent(_ event: AutomationEvent)
}

public final class AutomationHookManager: ObservableObject, AutomationHookManaging {
    public static let shared = AutomationHookManager()
    
    private let settings: AppSettings
    private let notificationCenter: DistributedNotificationCenter
    
    @Published public private(set) var lastDispatchedEvent: AutomationEvent?
    @Published public private(set) var lastDispatchedTimestamp: Date?
    
    public init(
        settings: AppSettings = .shared,
        notificationCenter: DistributedNotificationCenter = .default()
    ) {
        self.settings = settings
        self.notificationCenter = notificationCenter
    }
    
    public func handleEvent(_ event: AutomationEvent) {
        lastDispatchedEvent = event
        lastDispatchedTimestamp = Date()
        
        // 1. Dispatch macOS Distributed Notification for Raycast, Alfred, Hammerspoon, etc.
        let name = NSNotification.Name(event.notificationName)
        var userInfo: [String: Any] = ["timestamp": Date().timeIntervalSince1970]
        
        if case .smartPauseActivated(let reason) = event {
            userInfo["reason"] = reason
        }
        
        notificationCenter.postNotificationName(
            name,
            object: "com.breakreminder.BreakReminder",
            userInfo: userInfo,
            deliverImmediately: true
        )
        
        // 2. Execute user-configured script if explicitly enabled and consented
        if settings.customScriptsEnabled {
            executeCustomScript(for: event)
        }
    }
    
    private func executeCustomScript(for event: AutomationEvent) {
        let scriptPath: String
        switch event {
        case .breakStarted:
            scriptPath = settings.customScriptOnBreakStart.trimmingCharacters(in: .whitespacesAndNewlines)
        case .breakEnded:
            scriptPath = settings.customScriptOnBreakEnd.trimmingCharacters(in: .whitespacesAndNewlines)
        default:
            return
        }
        
        guard !scriptPath.isEmpty else { return }
        guard FileManager.default.isExecutableFile(atPath: scriptPath) else {
            NSLog("[AutomationHookManager] Target script is not executable: %@", scriptPath)
            return
        }
        
        DispatchQueue.global(qos: .utility).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: scriptPath)
            do {
                try process.run()
            } catch {
                NSLog("[AutomationHookManager] Failed to run user script: %@", error.localizedDescription)
            }
        }
    }
}
