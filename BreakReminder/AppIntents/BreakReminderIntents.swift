import AppIntents
import Foundation

@available(macOS 13.0, *)
public struct StartWorkSessionIntent: AppIntent {
    public static var title: LocalizedStringResource = "Start Work Session"
    public static var description = IntentDescription("Starts a focus work interval in Break Reminder.")
    public static var openAppWhenRun: Bool = false
    
    public init() {}
    
    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        TimerManager.shared.startWorkSession()
        let interval = AppSettings.shared.workIntervalMinutes
        return .result(dialog: "Started a \(interval)-minute work session.")
    }
}

@available(macOS 13.0, *)
public struct StartBreakIntent: AppIntent {
    public static var title: LocalizedStringResource = "Take a Break"
    public static var description = IntentDescription("Starts an immediate break in Break Reminder.")
    public static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Long Break", default: false)
    public var isLongBreak: Bool
    
    public init() {}
    
    public init(isLongBreak: Bool) {
        self.isLongBreak = isLongBreak
    }
    
    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        TimerManager.shared.startBreak(isLong: isLongBreak)
        let typeStr = isLongBreak ? "long break" : "short break"
        return .result(dialog: "Started a \(typeStr). Step away and rest your eyes!")
    }
}

@available(macOS 13.0, *)
public struct PauseBreakTimerIntent: AppIntent {
    public static var title: LocalizedStringResource = "Toggle Timer Pause"
    public static var description = IntentDescription("Pauses or resumes the active Break Reminder timer.")
    public static var openAppWhenRun: Bool = false
    
    public init() {}
    
    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let timer = TimerManager.shared
        if timer.status == .paused {
            timer.resumeTimer()
            return .result(dialog: "Resumed Break Reminder timer.")
        } else if timer.status == .working || timer.status == .onBreak {
            timer.pauseTimer()
            return .result(dialog: "Paused Break Reminder timer.")
        } else {
            return .result(dialog: "Break Reminder timer is currently idle.")
        }
    }
}

@available(macOS 13.0, *)
public struct GetScreenScoreIntent: AppIntent {
    public static var title: LocalizedStringResource = "Get Screen Score"
    public static var description = IntentDescription("Fetches today's ergonomic Screen Score (0-100).")
    public static var openAppWhenRun: Bool = false
    
    public init() {}
    
    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let today = StatisticsManager.shared.todayRecord
        let score = ScreenScore.calculate(for: today)
        return .result(dialog: "Today's Screen Score is \(score.value)/100 (\(score.rating)).")
    }
}

@available(macOS 13.0, *)
public struct BreakReminderShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartWorkSessionIntent(),
            phrases: [
                "Start work in \(.applicationName)",
                "Begin focus in \(.applicationName)"
            ],
            shortTitle: "Start Work Session",
            systemImageName: "laptopcomputer"
        )
        
        AppShortcut(
            intent: StartBreakIntent(),
            phrases: [
                "Take a break with \(.applicationName)",
                "Start a break in \(.applicationName)"
            ],
            shortTitle: "Take Break",
            systemImageName: "cup.and.saucer.fill"
        )
        
        AppShortcut(
            intent: GetScreenScoreIntent(),
            phrases: [
                "What is my screen score in \(.applicationName)?",
                "Check screen score with \(.applicationName)"
            ],
            shortTitle: "Get Screen Score",
            systemImageName: "gauge.medium"
        )
    }
}
