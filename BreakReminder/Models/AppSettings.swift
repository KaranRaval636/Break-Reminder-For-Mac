import SwiftUI
import Combine

public enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }
    
    public var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()
    
    private let defaults: UserDefaults
    
    // Keys
    private enum Keys {
        static let workIntervalMinutes = "workIntervalMinutes"
        static let shortBreakMinutes = "shortBreakMinutes"
        static let longBreakMinutes = "longBreakMinutes"
        static let longBreakFrequency = "longBreakFrequency"
        static let snoozeDurationMinutes = "snoozeDurationMinutes"
        static let autoStartBreaks = "autoStartBreaks"
        static let allowSnooze = "allowSnooze"
        static let allDisplays = "allDisplays"
        static let soundEnabled = "soundEnabled"
        static let notificationsEnabled = "notificationsEnabled"
        static let launchAtLogin = "launchAtLogin"
        static let autoStartWorkTimer = "autoStartWorkTimer"
        static let theme = "appTheme"
        
        // Expanded Keys
        static let breakProfile = "breakProfile"
        static let preBreakNotificationEnabled = "preBreakNotificationEnabled"
        static let preBreakNotificationLeadMinutes = "preBreakNotificationLeadMinutes"
        static let floatingCountdownEnabled = "floatingCountdownEnabled"
        static let snoozeLimit = "snoozeLimit"
        static let allowSkip = "allowSkip"
        static let allowScreenAccessDuringBreak = "allowScreenAccessDuringBreak"
        static let strictMode = "strictMode"
        static let manualBreakCompletion = "manualBreakCompletion"
        static let customBreakTitle = "customBreakTitle"
        static let customBreakSubtitle = "customBreakSubtitle"
        static let soundName = "soundName"
        static let backgroundStyle = "backgroundStyle"
        static let floatingPosition = "floatingPosition"
        static let floatingOnlyInPreBreak = "floatingOnlyInPreBreak"
        static let breathingGuideEnabled = "breathingGuideEnabled"
        static let customTips = "customTips"
        
        // Smart Pause Keys
        static let smartPauseEnabled = "smartPauseEnabled"
        static let smartPauseIdleEnabled = "smartPauseIdleEnabled"
        static let smartPauseIdleThresholdSeconds = "smartPauseIdleThresholdSeconds"
        static let smartPauseFullscreenEnabled = "smartPauseFullscreenEnabled"
        static let smartPauseMeetingEnabled = "smartPauseMeetingEnabled"
        static let smartPauseRecordingEnabled = "smartPauseRecordingEnabled"
        static let smartPauseVideoEnabled = "smartPauseVideoEnabled"
        static let smartPauseFocusAppsEnabled = "smartPauseFocusAppsEnabled"
        static let smartPausePostponeBufferSeconds = "smartPausePostponeBufferSeconds"
        static let excludedAppsData = "excludedAppsData"
        
        // Wellness Reminders Keys
        static let blinkRemindersEnabled = "blinkRemindersEnabled"
        static let blinkReminderIntervalMinutes = "blinkReminderIntervalMinutes"
        static let blinkCustomMessage = "blinkCustomMessage"
        static let blinkSoundEnabled = "blinkSoundEnabled"
        static let postureRemindersEnabled = "postureRemindersEnabled"
        static let postureReminderIntervalMinutes = "postureReminderIntervalMinutes"
        static let postureCustomMessage = "postureCustomMessage"
        static let postureSoundEnabled = "postureSoundEnabled"
        
        // Planned Breaks Keys
        static let plannedBreaksData = "plannedBreaksData"
        
        // Office Hours Keys
        static let officeHoursEnabled = "officeHoursEnabled"
        static let officeHoursStartHour = "officeHoursStartHour"
        static let officeHoursStartMinute = "officeHoursStartMinute"
        static let officeHoursEndHour = "officeHoursEndHour"
        static let officeHoursEndMinute = "officeHoursEndMinute"
        static let officeHoursDays = "officeHoursDays"
        static let officeHoursOverride = "officeHoursOverride"
        
        // Natural Break Keys
        static let naturalBreakEnabled = "naturalBreakEnabled"
        static let naturalBreakThresholdSeconds = "naturalBreakThresholdSeconds"
        static let customScriptsEnabled = "customScriptsEnabled"
        static let customScriptOnBreakStart = "customScriptOnBreakStart"
        static let customScriptOnBreakEnd = "customScriptOnBreakEnd"
    }
    
    // Defaults
    public static let defaultWorkIntervalMinutes: Int = 50
    public static let defaultShortBreakMinutes: Int = 5
    public static let defaultLongBreakMinutes: Int = 15
    public static let defaultLongBreakFrequency: Int = 4
    public static let defaultSnoozeDurationMinutes: Int = 5
    public static let defaultAutoStartBreaks: Bool = true
    public static let defaultAllowSnooze: Bool = true
    public static let defaultAllDisplays: Bool = true
    public static let defaultSoundEnabled: Bool = true
    public static let defaultNotificationsEnabled: Bool = true
    public static let defaultLaunchAtLogin: Bool = false
    public static let defaultAutoStartWorkTimer: Bool = false
    public static let defaultTheme: AppTheme = .system
    
    public static let defaultBlinkRemindersEnabled: Bool = true
    public static let defaultBlinkReminderIntervalMinutes: Int = 20
    public static let defaultBlinkCustomMessage: String = "Look 20 feet away for 20 seconds and blink naturally."
    public static let defaultBlinkSoundEnabled: Bool = false
    
    public static let defaultPostureRemindersEnabled: Bool = true
    public static let defaultPostureReminderIntervalMinutes: Int = 45
    public static let defaultPostureCustomMessage: String = "Roll your shoulders back, straighten your spine, and check your neck angle."
    public static let defaultPostureSoundEnabled: Bool = false
    
    public static let defaultPlannedBreaks: [PlannedBreak] = [
        PlannedBreak(name: "Lunch Break", hour: 13, minute: 0, durationMinutes: 45, repeatDays: [2, 3, 4, 5, 6]),
        PlannedBreak(name: "Afternoon Walk", hour: 16, minute: 30, durationMinutes: 15, repeatDays: [2, 3, 4, 5, 6])
    ]
    
    public static let defaultOfficeHoursEnabled: Bool = false
    public static let defaultOfficeHoursStartHour: Int = 9
    public static let defaultOfficeHoursStartMinute: Int = 0
    public static let defaultOfficeHoursEndHour: Int = 17
    public static let defaultOfficeHoursEndMinute: Int = 30
    public static let defaultOfficeHoursDays: [Int] = [2, 3, 4, 5, 6]
    public static let defaultOfficeHoursOverride: Bool = false
    
    public static let defaultNaturalBreakEnabled: Bool = true
    public static let defaultNaturalBreakThresholdSeconds: Int = 300
    public static let defaultCustomScriptsEnabled: Bool = false
    public static let defaultCustomScriptOnBreakStart: String = ""
    public static let defaultCustomScriptOnBreakEnd: String = ""
    
    public static let defaultSmartPauseEnabled: Bool = true
    public static let defaultSmartPauseIdleEnabled: Bool = true
    public static let defaultSmartPauseIdleThresholdSeconds: Int = 180
    public static let defaultSmartPauseFullscreenEnabled: Bool = true
    public static let defaultSmartPauseMeetingEnabled: Bool = true
    public static let defaultSmartPauseRecordingEnabled: Bool = true
    public static let defaultSmartPauseVideoEnabled: Bool = true
    public static let defaultSmartPauseFocusAppsEnabled: Bool = true
    public static let defaultSmartPausePostponeBufferSeconds: Int = 60
    public static let defaultExcludedApps: [ExcludedApp] = [
        ExcludedApp(bundleIdentifier: "com.apple.FinalCut", name: "Final Cut Pro"),
        ExcludedApp(bundleIdentifier: "com.apple.dt.Xcode", name: "Xcode"),
        ExcludedApp(bundleIdentifier: "com.adobe.Photoshop", name: "Adobe Photoshop")
    ]
    
    public static let defaultBreakProfile: BreakProfile = .balanced
    public static let defaultPreBreakNotificationEnabled: Bool = true
    public static let defaultPreBreakNotificationLeadMinutes: Int = 1
    public static let defaultFloatingCountdownEnabled: Bool = false
    public static let defaultFloatingPosition: String = "topRight"
    public static let defaultFloatingOnlyInPreBreak: Bool = false
    public static let defaultBreathingGuideEnabled: Bool = true
    public static let defaultSnoozeLimit: Int = 3
    public static let defaultAllowSkip: Bool = true
    public static let defaultAllowScreenAccessDuringBreak: Bool = true
    public static let defaultStrictMode: Bool = false
    public static let defaultManualBreakCompletion: Bool = false
    public static let defaultCustomBreakTitle: String = "Time to take a break!"
    public static let defaultCustomBreakSubtitle: String = "You've earned a moment to recharge."
    public static let defaultSoundName: String = "Bell"
    public static let defaultBackgroundStyle: String = "aurora"
    public static let defaultCustomTips: [String] = [
        "Look away from your screen and focus on something 20 feet away.",
        "Roll your shoulders back and relax your neck muscles.",
        "Take a slow, deep breath in... and exhale fully.",
        "Stand up, stretch your legs, and grab a fresh glass of water.",
        "Close your eyes for 30 seconds and let them completely rest.",
        "Rest your hands and shake out any wrist tension."
    ]
    
    // Limits
    public static let minWorkMinutes: Int = 1
    public static let maxWorkMinutes: Int = 180
    public static let minBreakMinutes: Int = 1
    public static let maxBreakMinutes: Int = 60
    public static let minFrequency: Int = 1
    public static let maxFrequency: Int = 12
    public static let minSnoozeMinutes: Int = 1
    public static let maxSnoozeMinutes: Int = 30
    
    @Published public var workIntervalMinutes: Int {
        didSet {
            let clamped = Self.clamp(workIntervalMinutes, min: Self.minWorkMinutes, max: Self.maxWorkMinutes)
            if clamped != workIntervalMinutes { workIntervalMinutes = clamped }
            defaults.set(workIntervalMinutes, forKey: Keys.workIntervalMinutes)
        }
    }
    
    @Published public var shortBreakMinutes: Int {
        didSet {
            let clamped = Self.clamp(shortBreakMinutes, min: Self.minBreakMinutes, max: Self.maxBreakMinutes)
            if clamped != shortBreakMinutes { shortBreakMinutes = clamped }
            defaults.set(shortBreakMinutes, forKey: Keys.shortBreakMinutes)
        }
    }
    
    @Published public var longBreakMinutes: Int {
        didSet {
            let clamped = Self.clamp(longBreakMinutes, min: Self.minBreakMinutes, max: Self.maxBreakMinutes)
            if clamped != longBreakMinutes { longBreakMinutes = clamped }
            defaults.set(longBreakMinutes, forKey: Keys.longBreakMinutes)
        }
    }
    
    @Published public var longBreakFrequency: Int {
        didSet {
            let clamped = Self.clamp(longBreakFrequency, min: Self.minFrequency, max: Self.maxFrequency)
            if clamped != longBreakFrequency { longBreakFrequency = clamped }
            defaults.set(longBreakFrequency, forKey: Keys.longBreakFrequency)
        }
    }
    
    @Published public var snoozeDurationMinutes: Int {
        didSet {
            let clamped = Self.clamp(snoozeDurationMinutes, min: Self.minSnoozeMinutes, max: Self.maxSnoozeMinutes)
            if clamped != snoozeDurationMinutes { snoozeDurationMinutes = clamped }
            defaults.set(snoozeDurationMinutes, forKey: Keys.snoozeDurationMinutes)
        }
    }
    
    @Published public var autoStartBreaks: Bool {
        didSet {
            defaults.set(autoStartBreaks, forKey: Keys.autoStartBreaks)
        }
    }
    
    @Published public var allowSnooze: Bool {
        didSet {
            defaults.set(allowSnooze, forKey: Keys.allowSnooze)
        }
    }
    
    @Published public var allDisplays: Bool {
        didSet {
            defaults.set(allDisplays, forKey: Keys.allDisplays)
        }
    }
    
    @Published public var soundEnabled: Bool {
        didSet {
            defaults.set(soundEnabled, forKey: Keys.soundEnabled)
        }
    }
    
    @Published public var notificationsEnabled: Bool {
        didSet {
            defaults.set(notificationsEnabled, forKey: Keys.notificationsEnabled)
        }
    }
    
    @Published public var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
        }
    }
    
    @Published public var autoStartWorkTimer: Bool {
        didSet {
            defaults.set(autoStartWorkTimer, forKey: Keys.autoStartWorkTimer)
        }
    }
    
    @Published public var theme: AppTheme {
        didSet {
            defaults.set(theme.rawValue, forKey: Keys.theme)
        }
    }
    
    // Expanded Properties
    @Published public var breakProfile: BreakProfile {
        didSet {
            defaults.set(breakProfile.rawValue, forKey: Keys.breakProfile)
        }
    }
    
    @Published public var preBreakNotificationEnabled: Bool {
        didSet {
            defaults.set(preBreakNotificationEnabled, forKey: Keys.preBreakNotificationEnabled)
        }
    }
    
    @Published public var preBreakNotificationLeadMinutes: Int {
        didSet {
            let clamped = Self.clamp(preBreakNotificationLeadMinutes, min: 1, max: 10)
            if clamped != preBreakNotificationLeadMinutes { preBreakNotificationLeadMinutes = clamped }
            defaults.set(preBreakNotificationLeadMinutes, forKey: Keys.preBreakNotificationLeadMinutes)
        }
    }
    
    @Published public var floatingCountdownEnabled: Bool {
        didSet {
            defaults.set(floatingCountdownEnabled, forKey: Keys.floatingCountdownEnabled)
        }
    }
    
    @Published public var snoozeLimit: Int {
        didSet {
            let clamped = Self.clamp(snoozeLimit, min: 0, max: 10)
            if clamped != snoozeLimit { snoozeLimit = clamped }
            defaults.set(snoozeLimit, forKey: Keys.snoozeLimit)
        }
    }
    
    @Published public var allowSkip: Bool {
        didSet {
            defaults.set(allowSkip, forKey: Keys.allowSkip)
        }
    }
    
    @Published public var allowScreenAccessDuringBreak: Bool {
        didSet {
            defaults.set(allowScreenAccessDuringBreak, forKey: Keys.allowScreenAccessDuringBreak)
        }
    }
    
    @Published public var strictMode: Bool {
        didSet {
            defaults.set(strictMode, forKey: Keys.strictMode)
        }
    }
    
    @Published public var manualBreakCompletion: Bool {
        didSet {
            defaults.set(manualBreakCompletion, forKey: Keys.manualBreakCompletion)
        }
    }
    
    @Published public var customBreakTitle: String {
        didSet {
            defaults.set(customBreakTitle, forKey: Keys.customBreakTitle)
        }
    }
    
    @Published public var customBreakSubtitle: String {
        didSet {
            defaults.set(customBreakSubtitle, forKey: Keys.customBreakSubtitle)
        }
    }
    
    @Published public var soundName: String {
        didSet {
            defaults.set(soundName, forKey: Keys.soundName)
        }
    }
    
    @Published public var backgroundStyle: String {
        didSet {
            defaults.set(backgroundStyle, forKey: Keys.backgroundStyle)
        }
    }
    
    @Published public var floatingPosition: String {
        didSet {
            defaults.set(floatingPosition, forKey: Keys.floatingPosition)
        }
    }
    
    @Published public var floatingOnlyInPreBreak: Bool {
        didSet {
            defaults.set(floatingOnlyInPreBreak, forKey: Keys.floatingOnlyInPreBreak)
        }
    }
    
    @Published public var breathingGuideEnabled: Bool {
        didSet {
            defaults.set(breathingGuideEnabled, forKey: Keys.breathingGuideEnabled)
        }
    }
    
    @Published public var customTips: [String] {
        didSet {
            defaults.set(customTips, forKey: Keys.customTips)
        }
    }
    
    // Smart Pause Published Properties
    @Published public var smartPauseEnabled: Bool {
        didSet {
            defaults.set(smartPauseEnabled, forKey: Keys.smartPauseEnabled)
        }
    }
    
    @Published public var smartPauseIdleEnabled: Bool {
        didSet {
            defaults.set(smartPauseIdleEnabled, forKey: Keys.smartPauseIdleEnabled)
        }
    }
    
    @Published public var smartPauseIdleThresholdSeconds: Int {
        didSet {
            let clamped = Self.clamp(smartPauseIdleThresholdSeconds, min: 30, max: 900)
            if clamped != smartPauseIdleThresholdSeconds { smartPauseIdleThresholdSeconds = clamped }
            defaults.set(smartPauseIdleThresholdSeconds, forKey: Keys.smartPauseIdleThresholdSeconds)
        }
    }
    
    @Published public var smartPauseFullscreenEnabled: Bool {
        didSet {
            defaults.set(smartPauseFullscreenEnabled, forKey: Keys.smartPauseFullscreenEnabled)
        }
    }
    
    @Published public var smartPauseMeetingEnabled: Bool {
        didSet {
            defaults.set(smartPauseMeetingEnabled, forKey: Keys.smartPauseMeetingEnabled)
        }
    }
    
    @Published public var smartPauseRecordingEnabled: Bool {
        didSet {
            defaults.set(smartPauseRecordingEnabled, forKey: Keys.smartPauseRecordingEnabled)
        }
    }
    
    @Published public var smartPauseVideoEnabled: Bool {
        didSet {
            defaults.set(smartPauseVideoEnabled, forKey: Keys.smartPauseVideoEnabled)
        }
    }
    
    @Published public var smartPauseFocusAppsEnabled: Bool {
        didSet {
            defaults.set(smartPauseFocusAppsEnabled, forKey: Keys.smartPauseFocusAppsEnabled)
        }
    }
    
    @Published public var smartPausePostponeBufferSeconds: Int {
        didSet {
            let clamped = Self.clamp(smartPausePostponeBufferSeconds, min: 10, max: 300)
            if clamped != smartPausePostponeBufferSeconds { smartPausePostponeBufferSeconds = clamped }
            defaults.set(smartPausePostponeBufferSeconds, forKey: Keys.smartPausePostponeBufferSeconds)
        }
    }
    
    @Published public var excludedApps: [ExcludedApp] {
        didSet {
            if let data = try? JSONEncoder().encode(excludedApps) {
                defaults.set(data, forKey: Keys.excludedAppsData)
            }
        }
    }
    
    // Wellness Reminders Properties
    @Published public var blinkRemindersEnabled: Bool {
        didSet { defaults.set(blinkRemindersEnabled, forKey: Keys.blinkRemindersEnabled) }
    }
    
    @Published public var blinkReminderIntervalMinutes: Int {
        didSet {
            let clamped = Self.clamp(blinkReminderIntervalMinutes, min: 5, max: 60)
            if clamped != blinkReminderIntervalMinutes { blinkReminderIntervalMinutes = clamped }
            defaults.set(blinkReminderIntervalMinutes, forKey: Keys.blinkReminderIntervalMinutes)
        }
    }
    
    @Published public var blinkCustomMessage: String {
        didSet { defaults.set(blinkCustomMessage, forKey: Keys.blinkCustomMessage) }
    }
    
    @Published public var blinkSoundEnabled: Bool {
        didSet { defaults.set(blinkSoundEnabled, forKey: Keys.blinkSoundEnabled) }
    }
    
    @Published public var postureRemindersEnabled: Bool {
        didSet { defaults.set(postureRemindersEnabled, forKey: Keys.postureRemindersEnabled) }
    }
    
    @Published public var postureReminderIntervalMinutes: Int {
        didSet {
            let clamped = Self.clamp(postureReminderIntervalMinutes, min: 10, max: 120)
            if clamped != postureReminderIntervalMinutes { postureReminderIntervalMinutes = clamped }
            defaults.set(postureReminderIntervalMinutes, forKey: Keys.postureReminderIntervalMinutes)
        }
    }
    
    @Published public var postureCustomMessage: String {
        didSet { defaults.set(postureCustomMessage, forKey: Keys.postureCustomMessage) }
    }
    
    @Published public var postureSoundEnabled: Bool {
        didSet { defaults.set(postureSoundEnabled, forKey: Keys.postureSoundEnabled) }
    }
    
    // Planned Breaks Properties
    @Published public var plannedBreaks: [PlannedBreak] {
        didSet {
            if let data = try? JSONEncoder().encode(plannedBreaks) {
                defaults.set(data, forKey: Keys.plannedBreaksData)
            }
        }
    }
    
    // Office Hours Properties
    @Published public var officeHoursEnabled: Bool {
        didSet { defaults.set(officeHoursEnabled, forKey: Keys.officeHoursEnabled) }
    }
    
    @Published public var officeHoursStartHour: Int {
        didSet { defaults.set(officeHoursStartHour, forKey: Keys.officeHoursStartHour) }
    }
    
    @Published public var officeHoursStartMinute: Int {
        didSet { defaults.set(officeHoursStartMinute, forKey: Keys.officeHoursStartMinute) }
    }
    
    @Published public var officeHoursEndHour: Int {
        didSet { defaults.set(officeHoursEndHour, forKey: Keys.officeHoursEndHour) }
    }
    
    @Published public var officeHoursEndMinute: Int {
        didSet { defaults.set(officeHoursEndMinute, forKey: Keys.officeHoursEndMinute) }
    }
    
    @Published public var officeHoursDays: [Int] {
        didSet { defaults.set(officeHoursDays, forKey: Keys.officeHoursDays) }
    }
    
    @Published public var officeHoursOverride: Bool {
        didSet { defaults.set(officeHoursOverride, forKey: Keys.officeHoursOverride) }
    }
    
    // Natural Break Properties
    @Published public var naturalBreakEnabled: Bool {
        didSet { defaults.set(naturalBreakEnabled, forKey: Keys.naturalBreakEnabled) }
    }
    
    @Published public var naturalBreakThresholdSeconds: Int {
        didSet {
            let clamped = Self.clamp(naturalBreakThresholdSeconds, min: 60, max: 1800)
            if clamped != naturalBreakThresholdSeconds { naturalBreakThresholdSeconds = clamped }
            defaults.set(naturalBreakThresholdSeconds, forKey: Keys.naturalBreakThresholdSeconds)
        }
    }
    
    @Published public var customScriptsEnabled: Bool {
        didSet { defaults.set(customScriptsEnabled, forKey: Keys.customScriptsEnabled) }
    }
    
    @Published public var customScriptOnBreakStart: String {
        didSet { defaults.set(customScriptOnBreakStart, forKey: Keys.customScriptOnBreakStart) }
    }
    
    @Published public var customScriptOnBreakEnd: String {
        didSet { defaults.set(customScriptOnBreakEnd, forKey: Keys.customScriptOnBreakEnd) }
    }
    
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        
        let storedWork = defaults.object(forKey: Keys.workIntervalMinutes) as? Int ?? Self.defaultWorkIntervalMinutes
        self.workIntervalMinutes = Self.clamp(storedWork, min: Self.minWorkMinutes, max: Self.maxWorkMinutes)
        
        let storedShort = defaults.object(forKey: Keys.shortBreakMinutes) as? Int ?? Self.defaultShortBreakMinutes
        self.shortBreakMinutes = Self.clamp(storedShort, min: Self.minBreakMinutes, max: Self.maxBreakMinutes)
        
        let storedLong = defaults.object(forKey: Keys.longBreakMinutes) as? Int ?? Self.defaultLongBreakMinutes
        self.longBreakMinutes = Self.clamp(storedLong, min: Self.minBreakMinutes, max: Self.maxBreakMinutes)
        
        let storedFreq = defaults.object(forKey: Keys.longBreakFrequency) as? Int ?? Self.defaultLongBreakFrequency
        self.longBreakFrequency = Self.clamp(storedFreq, min: Self.minFrequency, max: Self.maxFrequency)
        
        let storedSnooze = defaults.object(forKey: Keys.snoozeDurationMinutes) as? Int ?? Self.defaultSnoozeDurationMinutes
        self.snoozeDurationMinutes = Self.clamp(storedSnooze, min: Self.minSnoozeMinutes, max: Self.maxSnoozeMinutes)
        
        self.autoStartBreaks = defaults.object(forKey: Keys.autoStartBreaks) as? Bool ?? Self.defaultAutoStartBreaks
        self.allowSnooze = defaults.object(forKey: Keys.allowSnooze) as? Bool ?? Self.defaultAllowSnooze
        self.allDisplays = defaults.object(forKey: Keys.allDisplays) as? Bool ?? Self.defaultAllDisplays
        self.soundEnabled = defaults.object(forKey: Keys.soundEnabled) as? Bool ?? Self.defaultSoundEnabled
        self.notificationsEnabled = defaults.object(forKey: Keys.notificationsEnabled) as? Bool ?? Self.defaultNotificationsEnabled
        self.launchAtLogin = defaults.object(forKey: Keys.launchAtLogin) as? Bool ?? Self.defaultLaunchAtLogin
        self.autoStartWorkTimer = defaults.object(forKey: Keys.autoStartWorkTimer) as? Bool ?? Self.defaultAutoStartWorkTimer
        
        if let storedThemeRaw = defaults.string(forKey: Keys.theme),
           let themeVal = AppTheme(rawValue: storedThemeRaw) {
            self.theme = themeVal
        } else {
            self.theme = Self.defaultTheme
        }
        
        if let profileRaw = defaults.string(forKey: Keys.breakProfile),
           let profile = BreakProfile(rawValue: profileRaw) {
            self.breakProfile = profile
        } else {
            self.breakProfile = Self.defaultBreakProfile
        }
        
        self.preBreakNotificationEnabled = defaults.object(forKey: Keys.preBreakNotificationEnabled) as? Bool ?? Self.defaultPreBreakNotificationEnabled
        self.preBreakNotificationLeadMinutes = defaults.object(forKey: Keys.preBreakNotificationLeadMinutes) as? Int ?? Self.defaultPreBreakNotificationLeadMinutes
        self.floatingCountdownEnabled = defaults.object(forKey: Keys.floatingCountdownEnabled) as? Bool ?? Self.defaultFloatingCountdownEnabled
        self.floatingPosition = defaults.string(forKey: Keys.floatingPosition) ?? Self.defaultFloatingPosition
        self.floatingOnlyInPreBreak = defaults.object(forKey: Keys.floatingOnlyInPreBreak) as? Bool ?? Self.defaultFloatingOnlyInPreBreak
        self.breathingGuideEnabled = defaults.object(forKey: Keys.breathingGuideEnabled) as? Bool ?? Self.defaultBreathingGuideEnabled
        self.snoozeLimit = defaults.object(forKey: Keys.snoozeLimit) as? Int ?? Self.defaultSnoozeLimit
        self.allowSkip = defaults.object(forKey: Keys.allowSkip) as? Bool ?? Self.defaultAllowSkip
        self.allowScreenAccessDuringBreak = defaults.object(forKey: Keys.allowScreenAccessDuringBreak) as? Bool ?? Self.defaultAllowScreenAccessDuringBreak
        self.strictMode = defaults.object(forKey: Keys.strictMode) as? Bool ?? Self.defaultStrictMode
        self.manualBreakCompletion = defaults.object(forKey: Keys.manualBreakCompletion) as? Bool ?? Self.defaultManualBreakCompletion
        self.customBreakTitle = defaults.string(forKey: Keys.customBreakTitle) ?? Self.defaultCustomBreakTitle
        self.customBreakSubtitle = defaults.string(forKey: Keys.customBreakSubtitle) ?? Self.defaultCustomBreakSubtitle
        self.soundName = defaults.string(forKey: Keys.soundName) ?? Self.defaultSoundName
        self.backgroundStyle = defaults.string(forKey: Keys.backgroundStyle) ?? Self.defaultBackgroundStyle
        self.customTips = (defaults.array(forKey: Keys.customTips) as? [String]) ?? Self.defaultCustomTips
        
        self.smartPauseEnabled = defaults.object(forKey: Keys.smartPauseEnabled) as? Bool ?? Self.defaultSmartPauseEnabled
        self.smartPauseIdleEnabled = defaults.object(forKey: Keys.smartPauseIdleEnabled) as? Bool ?? Self.defaultSmartPauseIdleEnabled
        self.smartPauseIdleThresholdSeconds = defaults.object(forKey: Keys.smartPauseIdleThresholdSeconds) as? Int ?? Self.defaultSmartPauseIdleThresholdSeconds
        self.smartPauseFullscreenEnabled = defaults.object(forKey: Keys.smartPauseFullscreenEnabled) as? Bool ?? Self.defaultSmartPauseFullscreenEnabled
        self.smartPauseMeetingEnabled = defaults.object(forKey: Keys.smartPauseMeetingEnabled) as? Bool ?? Self.defaultSmartPauseMeetingEnabled
        self.smartPauseRecordingEnabled = defaults.object(forKey: Keys.smartPauseRecordingEnabled) as? Bool ?? Self.defaultSmartPauseRecordingEnabled
        self.smartPauseVideoEnabled = defaults.object(forKey: Keys.smartPauseVideoEnabled) as? Bool ?? Self.defaultSmartPauseVideoEnabled
        self.smartPauseFocusAppsEnabled = defaults.object(forKey: Keys.smartPauseFocusAppsEnabled) as? Bool ?? Self.defaultSmartPauseFocusAppsEnabled
        self.smartPausePostponeBufferSeconds = defaults.object(forKey: Keys.smartPausePostponeBufferSeconds) as? Int ?? Self.defaultSmartPausePostponeBufferSeconds
        
        if let data = defaults.data(forKey: Keys.excludedAppsData),
           let decoded = try? JSONDecoder().decode([ExcludedApp].self, from: data) {
            self.excludedApps = decoded
        } else {
            self.excludedApps = Self.defaultExcludedApps
        }
        
        // Wellness Reminders Init
        self.blinkRemindersEnabled = defaults.object(forKey: Keys.blinkRemindersEnabled) as? Bool ?? Self.defaultBlinkRemindersEnabled
        self.blinkReminderIntervalMinutes = defaults.object(forKey: Keys.blinkReminderIntervalMinutes) as? Int ?? Self.defaultBlinkReminderIntervalMinutes
        self.blinkCustomMessage = defaults.string(forKey: Keys.blinkCustomMessage) ?? Self.defaultBlinkCustomMessage
        self.blinkSoundEnabled = defaults.object(forKey: Keys.blinkSoundEnabled) as? Bool ?? Self.defaultBlinkSoundEnabled
        
        self.postureRemindersEnabled = defaults.object(forKey: Keys.postureRemindersEnabled) as? Bool ?? Self.defaultPostureRemindersEnabled
        self.postureReminderIntervalMinutes = defaults.object(forKey: Keys.postureReminderIntervalMinutes) as? Int ?? Self.defaultPostureReminderIntervalMinutes
        self.postureCustomMessage = defaults.string(forKey: Keys.postureCustomMessage) ?? Self.defaultPostureCustomMessage
        self.postureSoundEnabled = defaults.object(forKey: Keys.postureSoundEnabled) as? Bool ?? Self.defaultPostureSoundEnabled
        
        // Planned Breaks Init
        if let data = defaults.data(forKey: Keys.plannedBreaksData),
           let decoded = try? JSONDecoder().decode([PlannedBreak].self, from: data) {
            self.plannedBreaks = decoded
        } else {
            self.plannedBreaks = Self.defaultPlannedBreaks
        }
        
        // Office Hours Init
        self.officeHoursEnabled = defaults.object(forKey: Keys.officeHoursEnabled) as? Bool ?? Self.defaultOfficeHoursEnabled
        self.officeHoursStartHour = defaults.object(forKey: Keys.officeHoursStartHour) as? Int ?? Self.defaultOfficeHoursStartHour
        self.officeHoursStartMinute = defaults.object(forKey: Keys.officeHoursStartMinute) as? Int ?? Self.defaultOfficeHoursStartMinute
        self.officeHoursEndHour = defaults.object(forKey: Keys.officeHoursEndHour) as? Int ?? Self.defaultOfficeHoursEndHour
        self.officeHoursEndMinute = defaults.object(forKey: Keys.officeHoursEndMinute) as? Int ?? Self.defaultOfficeHoursEndMinute
        self.officeHoursDays = (defaults.array(forKey: Keys.officeHoursDays) as? [Int]) ?? Self.defaultOfficeHoursDays
        self.officeHoursOverride = defaults.object(forKey: Keys.officeHoursOverride) as? Bool ?? Self.defaultOfficeHoursOverride
        
        // Natural Break Init
        self.naturalBreakEnabled = defaults.object(forKey: Keys.naturalBreakEnabled) as? Bool ?? Self.defaultNaturalBreakEnabled
        self.naturalBreakThresholdSeconds = defaults.object(forKey: Keys.naturalBreakThresholdSeconds) as? Int ?? Self.defaultNaturalBreakThresholdSeconds
        
        // Custom Scripts Init
        self.customScriptsEnabled = defaults.object(forKey: Keys.customScriptsEnabled) as? Bool ?? Self.defaultCustomScriptsEnabled
        self.customScriptOnBreakStart = defaults.string(forKey: Keys.customScriptOnBreakStart) ?? Self.defaultCustomScriptOnBreakStart
        self.customScriptOnBreakEnd = defaults.string(forKey: Keys.customScriptOnBreakEnd) ?? Self.defaultCustomScriptOnBreakEnd
    }
    
    public func applyProfile(_ profile: BreakProfile) {
        self.breakProfile = profile
        if profile != .custom {
            self.workIntervalMinutes = profile.defaultWorkMinutes
            self.shortBreakMinutes = profile.defaultShortBreakMinutes
            self.longBreakMinutes = profile.defaultLongBreakMinutes
            self.longBreakFrequency = profile.defaultLongBreakFrequency
        }
    }
    
    public func restoreDefaults() {
        workIntervalMinutes = Self.defaultWorkIntervalMinutes
        shortBreakMinutes = Self.defaultShortBreakMinutes
        longBreakMinutes = Self.defaultLongBreakMinutes
        longBreakFrequency = Self.defaultLongBreakFrequency
        snoozeDurationMinutes = Self.defaultSnoozeDurationMinutes
        autoStartBreaks = Self.defaultAutoStartBreaks
        allowSnooze = Self.defaultAllowSnooze
        allDisplays = Self.defaultAllDisplays
        soundEnabled = Self.defaultSoundEnabled
        notificationsEnabled = Self.defaultNotificationsEnabled
        launchAtLogin = Self.defaultLaunchAtLogin
        autoStartWorkTimer = Self.defaultAutoStartWorkTimer
        theme = Self.defaultTheme
        breakProfile = Self.defaultBreakProfile
        preBreakNotificationEnabled = Self.defaultPreBreakNotificationEnabled
        preBreakNotificationLeadMinutes = Self.defaultPreBreakNotificationLeadMinutes
        floatingCountdownEnabled = Self.defaultFloatingCountdownEnabled
        floatingPosition = Self.defaultFloatingPosition
        floatingOnlyInPreBreak = Self.defaultFloatingOnlyInPreBreak
        breathingGuideEnabled = Self.defaultBreathingGuideEnabled
        snoozeLimit = Self.defaultSnoozeLimit
        allowSkip = Self.defaultAllowSkip
        allowScreenAccessDuringBreak = Self.defaultAllowScreenAccessDuringBreak
        strictMode = Self.defaultStrictMode
        manualBreakCompletion = Self.defaultManualBreakCompletion
        customBreakTitle = Self.defaultCustomBreakTitle
        customBreakSubtitle = Self.defaultCustomBreakSubtitle
        soundName = Self.defaultSoundName
        backgroundStyle = Self.defaultBackgroundStyle
        customTips = Self.defaultCustomTips
        smartPauseEnabled = Self.defaultSmartPauseEnabled
        smartPauseIdleEnabled = Self.defaultSmartPauseIdleEnabled
        smartPauseIdleThresholdSeconds = Self.defaultSmartPauseIdleThresholdSeconds
        smartPauseFullscreenEnabled = Self.defaultSmartPauseFullscreenEnabled
        smartPauseMeetingEnabled = Self.defaultSmartPauseMeetingEnabled
        smartPauseRecordingEnabled = Self.defaultSmartPauseRecordingEnabled
        smartPauseVideoEnabled = Self.defaultSmartPauseVideoEnabled
        smartPauseFocusAppsEnabled = Self.defaultSmartPauseFocusAppsEnabled
        smartPausePostponeBufferSeconds = Self.defaultSmartPausePostponeBufferSeconds
        excludedApps = Self.defaultExcludedApps
        
        blinkRemindersEnabled = Self.defaultBlinkRemindersEnabled
        blinkReminderIntervalMinutes = Self.defaultBlinkReminderIntervalMinutes
        blinkCustomMessage = Self.defaultBlinkCustomMessage
        blinkSoundEnabled = Self.defaultBlinkSoundEnabled
        postureRemindersEnabled = Self.defaultPostureRemindersEnabled
        postureReminderIntervalMinutes = Self.defaultPostureReminderIntervalMinutes
        postureCustomMessage = Self.defaultPostureCustomMessage
        postureSoundEnabled = Self.defaultPostureSoundEnabled
        
        plannedBreaks = Self.defaultPlannedBreaks
        
        officeHoursEnabled = Self.defaultOfficeHoursEnabled
        officeHoursStartHour = Self.defaultOfficeHoursStartHour
        officeHoursStartMinute = Self.defaultOfficeHoursStartMinute
        officeHoursEndHour = Self.defaultOfficeHoursEndHour
        officeHoursEndMinute = Self.defaultOfficeHoursEndMinute
        officeHoursDays = Self.defaultOfficeHoursDays
        officeHoursOverride = Self.defaultOfficeHoursOverride
        
        naturalBreakEnabled = Self.defaultNaturalBreakEnabled
        naturalBreakThresholdSeconds = Self.defaultNaturalBreakThresholdSeconds
        
        customScriptsEnabled = Self.defaultCustomScriptsEnabled
        customScriptOnBreakStart = Self.defaultCustomScriptOnBreakStart
        customScriptOnBreakEnd = Self.defaultCustomScriptOnBreakEnd
    }
    
    private static func clamp(_ value: Int, min: Int, max: Int) -> Int {
        Swift.min(Swift.max(value, min), max)
    }
}
