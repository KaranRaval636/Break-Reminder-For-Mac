import Foundation
import UserNotifications

public protocol NotificationManaging: AnyObject {
    func requestAuthorizationIfNeeded()
    func sendWorkFinishedNotification(isLongBreak: Bool)
    func sendBreakFinishedNotification()
    func sendPreBreakNotification(minutesRemaining: Int)
    func cancelPendingNotifications()
}

public extension NotificationManaging {
    func sendPreBreakNotification(minutesRemaining: Int) {}
}

public final class NotificationManager: NSObject, NotificationManaging, UNUserNotificationCenterDelegate {
    public static let shared = NotificationManager()
    
    public static let breakFinishedCategoryIdentifier = "BreakReminder.category.breakFinished"
    public static let startWorkSessionActionIdentifier = "BreakReminder.action.startWorkSession"
    
    public static var isUserNotificationCenterSupported: Bool {
        guard NSClassFromString("XCTestCase") == nil else { return false }
        return Bundle.main.bundleURL.pathExtension == "app" || (Bundle.main.infoDictionary?["CFBundlePackageType"] as? String == "APPL")
    }
    
    private let center: UNUserNotificationCenter?
    private let settings: AppSettings
    private var isAuthorized: Bool = false
    
    public var onStartWorkSessionRequested: (() -> Void)?
    
    public init(
        center: UNUserNotificationCenter? = (isUserNotificationCenterSupported ? .current() : nil),
        settings: AppSettings = .shared
    ) {
        self.center = center
        self.settings = settings
        super.init()
        
        setupNotificationCategoriesAndDelegate()
    }
    
    public func setupNotificationCategoriesAndDelegate() {
        guard let center = center else { return }
        center.delegate = self
        
        let startAction = UNNotificationAction(
            identifier: Self.startWorkSessionActionIdentifier,
            title: "Start Session",
            options: [.foreground]
        )
        
        let breakFinishedCategory = UNNotificationCategory(
            identifier: Self.breakFinishedCategoryIdentifier,
            actions: [startAction],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([breakFinishedCategory])
    }
    
    public func requestAuthorizationIfNeeded() {
        guard settings.notificationsEnabled else { return }
        guard let center = center else { return }
        
        center.getNotificationSettings { [weak self] currentSettings in
            guard let self = self else { return }
            switch currentSettings.authorizationStatus {
            case .notDetermined:
                self.center?.requestAuthorization(options: [.alert, .sound]) { granted, _ in
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
    
    public func sendPreBreakNotification(minutesRemaining: Int) {
        guard settings.notificationsEnabled && settings.preBreakNotificationEnabled else { return }
        guard let center = center else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Break Starting Soon"
        let minuteText = minutesRemaining == 1 ? "1 minute" : "\(minutesRemaining) minutes"
        content.body = "Your screen break begins in \(minuteText). Wrap up your thoughts!"
        
        if settings.soundEnabled {
            content.sound = .default
        }
        
        let request = UNNotificationRequest(
            identifier: "BreakReminder.preBreak.\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        center.add(request) { error in
            if let error = error {
                NSLog("[NotificationManager] Error posting pre-break notification: %@", error.localizedDescription)
            }
        }
    }
    
    public func sendWorkFinishedNotification(isLongBreak: Bool) {
        guard settings.notificationsEnabled else { return }
        guard let center = center else { return }
        
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
        guard let center = center else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Break Finished"
        content.body = "Ready to get back in the flow? Start your next session whenever you're ready."
        content.categoryIdentifier = Self.breakFinishedCategoryIdentifier
        
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
        center?.removeAllPendingNotificationRequests()
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionId = response.actionIdentifier
        if actionId == Self.startWorkSessionActionIdentifier || actionId == UNNotificationDefaultActionIdentifier {
            DispatchQueue.main.async { [weak self] in
                self?.onStartWorkSessionRequested?()
            }
        }
        completionHandler()
    }
}
