import Foundation
import UserNotifications

public protocol NotificationManaging: AnyObject {
    func requestAuthorizationIfNeeded()
    func sendWorkFinishedNotification(isLongBreak: Bool)
    func sendBreakFinishedNotification()
    func cancelPendingNotifications()
}

public final class NotificationManager: NotificationManaging {
    public static let shared = NotificationManager()
    
    private let center: UNUserNotificationCenter
    private let settings: AppSettings
    private var isAuthorized: Bool = false
    
    public init(
        center: UNUserNotificationCenter = .current(),
        settings: AppSettings = .shared
    ) {
        self.center = center
        self.settings = settings
    }
    
    public func requestAuthorizationIfNeeded() {
        guard settings.notificationsEnabled else { return }
        
        center.getNotificationSettings { [weak self] currentSettings in
            guard let self = self else { return }
            switch currentSettings.authorizationStatus {
            case .notDetermined:
                self.center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    self.isAuthorized = granted
                }
            case .authorized, .provisional:
                self.isAuthorized = true
            case .denied:
                self.isAuthorized = false
            @unknown default:
                self.isAuthorized = false
            }
        }
    }
    
    public func sendWorkFinishedNotification(isLongBreak: Bool) {
        guard settings.notificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Time for a Break!"
        content.body = isLongBreak
            ? "Great work! You've earned a well-deserved long break."
            : "Work session completed. Take a few minutes to rest your eyes and stretch."
        
        if settings.soundEnabled {
            content.sound = .default
        }
        
        let request = UNNotificationRequest(
            identifier: "BreakReminder.workFinished.\(UUID().uuidString)",
            content: content,
            trigger: nil // Deliver immediately
        )
        
        center.add(request) { error in
            if let error = error {
                NSLog("[NotificationManager] Error posting notification: %@", error.localizedDescription)
            }
        }
    }
    
    public func sendBreakFinishedNotification() {
        guard settings.notificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Break Finished"
        content.body = "Ready to get back in the flow? Start your next session whenever you're ready."
        
        if settings.soundEnabled {
            content.sound = .default
        }
        
        let request = UNNotificationRequest(
            identifier: "BreakReminder.breakFinished.\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        center.add(request) { error in
            if let error = error {
                NSLog("[NotificationManager] Error posting notification: %@", error.localizedDescription)
            }
        }
    }
    
    public func cancelPendingNotifications() {
        center.removeAllPendingNotificationRequests()
    }
}
