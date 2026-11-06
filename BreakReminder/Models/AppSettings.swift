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
    }
    
    private static func clamp(_ value: Int, min: Int, max: Int) -> Int {
        Swift.min(Swift.max(value, min), max)
    }
}
