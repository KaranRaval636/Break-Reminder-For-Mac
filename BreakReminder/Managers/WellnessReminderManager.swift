import Foundation
import UserNotifications
import Combine

public protocol WellnessReminderManaging: AnyObject {
    func evaluateReminders()
    func triggerBlinkReminderNow()
    func triggerPostureReminderNow()
}

public final class WellnessReminderManager: ObservableObject, WellnessReminderManaging {
    public static let shared = WellnessReminderManager()
    
    private let settings: AppSettings
    private let timerManager: TimerManager
    private let smartPauseManager: SmartPauseManager
    private let notificationCenter: UNUserNotificationCenter
    
    private var blinkLastFired: Date
    private var postureLastFired: Date
    private var ticker: Timer?
    
    public init(
        settings: AppSettings = .shared,
        timerManager: TimerManager = .shared,
        smartPauseManager: SmartPauseManager = .shared,
        notificationCenter: UNUserNotificationCenter = .current()
    ) {
        self.settings = settings
        self.timerManager = timerManager
        self.smartPauseManager = smartPauseManager
        self.notificationCenter = notificationCenter
        
        let now = Date()
        self.blinkLastFired = now
        self.postureLastFired = now
        
        startTicker()
    }
    
    deinit {
        ticker?.invalidate()
    }
    
    private func startTicker() {
        ticker?.invalidate()
        // Check every 30 seconds
        ticker = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.evaluateReminders()
        }
    }
    
    public func shouldSuppressReminders() -> Bool {
        return timerManager.status != .working || smartPauseManager.isSmartPaused
    }
    
    public func evaluateReminders() {
        let now = Date()
        
        // Suppression checks: Don't nudge during full-screen break or meetings
        guard timerManager.status == .working else { return }
        guard !smartPauseManager.isSmartPaused else { return }
        
        // 1. Blink Reminder Evaluation
        if settings.blinkRemindersEnabled {
            let intervalSecs = TimeInterval(settings.blinkReminderIntervalMinutes * 60)
            if now.timeIntervalSince(blinkLastFired) >= intervalSecs {
                fireBlinkNotification()
                blinkLastFired = now
            }
        }
        
        // 2. Posture Reminder Evaluation
        if settings.postureRemindersEnabled {
            let intervalSecs = TimeInterval(settings.postureReminderIntervalMinutes * 60)
            if now.timeIntervalSince(postureLastFired) >= intervalSecs {
                firePostureNotification()
                postureLastFired = now
            }
        }
    }
    
    public func triggerBlinkReminderNow() {
        fireBlinkNotification()
        blinkLastFired = Date()
    }
    
    public func triggerPostureReminderNow() {
        firePostureNotification()
        postureLastFired = Date()
    }
    
    private func fireBlinkNotification() {
        guard settings.notificationsEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = "Blink & Rest Eyes (20-20-20)"
        content.body = settings.blinkCustomMessage
        if settings.blinkSoundEnabled {
            content.sound = .default
        }
        
        let request = UNNotificationRequest(
            identifier: "BreakReminder.wellness.blink.\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        notificationCenter.add(request) { error in
            if let error = error {
                NSLog("[WellnessReminderManager] Blink notification error: %@", error.localizedDescription)
            }
        }
    }
    
    private func firePostureNotification() {
        guard settings.notificationsEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = "Ergonomic Posture Check"
        content.body = settings.postureCustomMessage
        if settings.postureSoundEnabled {
            content.sound = .default
        }
        
        let request = UNNotificationRequest(
            identifier: "BreakReminder.wellness.posture.\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        notificationCenter.add(request) { error in
            if let error = error {
                NSLog("[WellnessReminderManager] Posture notification error: %@", error.localizedDescription)
            }
        }
    }
}
