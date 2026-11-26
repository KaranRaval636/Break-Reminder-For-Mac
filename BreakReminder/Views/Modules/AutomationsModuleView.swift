import SwiftUI

public struct AutomationsModuleView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var automationHookManager: AutomationHookManager
    @State private var testingFeedback: String?
    
    public init(
        settings: AppSettings = .shared,
        automationHookManager: AutomationHookManager = .shared
    ) {
        self.settings = settings
        self.automationHookManager = automationHookManager
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Automations & Integrations")
                        .font(.system(size: 24, weight: .bold))
                    Text("Connect Break Reminder to Apple Shortcuts, Raycast, Alfred, custom scripts, and macOS Focus.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Live Activity Pill
                if let lastEvent = automationHookManager.lastDispatchedEvent,
                   let timestamp = automationHookManager.lastDispatchedTimestamp {
                    HStack(spacing: 12) {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.accentColor)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Last Broadcast Event: \(lastEvent.notificationName)")
                                .font(.caption.bold())
                            Text("Dispatched at \(DateFormatter.localizedString(from: timestamp, dateStyle: .none, timeStyle: .medium))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.accentColor.opacity(0.1)))
                }
                
                // Feedback Banner
                if let feedback = testingFeedback {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(feedback)
                            .font(.subheadline)
                        Spacer()
                        Button("Dismiss") {
                            testingFeedback = nil
                        }
                        .buttonStyle(.plain)
                        .font(.caption)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.green.opacity(0.1)))
                }
                
                // Section 1: Apple Shortcuts & App Intents
                shortcutsSection
                
                // Section 2: Distributed Notifications (Raycast, Alfred, Hammerspoon)
                distributedNotificationsSection
                
                // Section 3: Custom Shell & AppleScripts
                customScriptsSection
                
                // Section 4: Focus Filter Guide
                focusModesSection
            }
            .padding(24)
        }
    }
    
    // MARK: - Shortcuts Section
    
    private var shortcutsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Apple Shortcuts & Siri Intents")
                .font(.headline)
            
            Text("Break Reminder natively exposes App Intents to the macOS Shortcuts app. You can automate break schedules, stream deck triggers, or ask Siri directly.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                shortcutRow(
                    title: "Start Work Session",
                    description: "Begins a work countdown interval.",
                    phrase: "Hey Siri, start work in Break Reminder"
                ) {
                    TimerManager.shared.startWorkSession()
                    testingFeedback = "Triggered 'Start Work Session' intent."
                }
                
                shortcutRow(
                    title: "Take Break Now",
                    description: "Instantly begins an immediate rest overlay.",
                    phrase: "Hey Siri, take a break with Break Reminder"
                ) {
                    TimerManager.shared.startBreak(isLong: false)
                    testingFeedback = "Triggered 'Take Break Now' intent."
                }
                
                shortcutRow(
                    title: "Toggle Timer Pause",
                    description: "Pauses or resumes countdown.",
                    phrase: "Shortcuts: Toggle Timer Pause"
                ) {
                    if TimerManager.shared.status == .paused {
                        TimerManager.shared.resumeTimer()
                        testingFeedback = "Resumed timer."
                    } else {
                        TimerManager.shared.pauseTimer()
                        testingFeedback = "Paused timer."
                    }
                }
                
                shortcutRow(
                    title: "Get Screen Score",
                    description: "Fetches current day's wellness score (0-100).",
                    phrase: "Hey Siri, what is my screen score in Break Reminder?"
                ) {
                    let score = ScreenScore.calculate(for: StatisticsManager.shared.todayRecord)
                    testingFeedback = "Today's Screen Score: \(score.value)/100 (\(score.rating))."
                }
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
    }
    
    // MARK: - Distributed Notifications
    
    private var distributedNotificationsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Distributed Notification Center")
                .font(.headline)
            
            Text("Break Reminder broadcasts system-wide notifications using macOS DistributedNotificationCenter. External tools like Raycast, Alfred, Hammerspoon, or custom Daemons can listen to these events.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                notificationItem(name: "com.breakreminder.WorkSessionStarted", description: "Dispatched when a work interval starts.")
                notificationItem(name: "com.breakreminder.ShortBreakStarted", description: "Dispatched when a short break begins.")
                notificationItem(name: "com.breakreminder.LongBreakStarted", description: "Dispatched when a long rest begins.")
                notificationItem(name: "com.breakreminder.BreakEnded", description: "Dispatched when a break overlay closes.")
                notificationItem(name: "com.breakreminder.BreakSkipped", description: "Dispatched when a user skips a scheduled break.")
                notificationItem(name: "com.breakreminder.SmartPauseActivated", description: "Dispatched when Smart Pause halts the timer (carries 'reason' in userInfo).")
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
    }
    
    // MARK: - Custom Scripts Section
    
    private var customScriptsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Enable Custom Script Execution", isOn: $settings.customScriptsEnabled)
                .font(.headline)
            
            Text("Execute local shell scripts (.sh) or AppleScripts (.scpt) on break lifecycle events. Scripts run in the background under your user permissions.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if settings.customScriptsEnabled {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Break Started Script Path:")
                        .font(.subheadline.bold())
                    
                    TextField("/path/to/turn_off_desk_lamp.sh", text: $settings.customScriptOnBreakStart)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                    
                    Text("Executed immediately when a break begins (e.g., smart home lights, mute music).")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Break Ended Script Path:")
                        .font(.subheadline.bold())
                    
                    TextField("/path/to/turn_on_desk_lamp.sh", text: $settings.customScriptOnBreakEnd)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                    
                    Text("Executed when a break finishes or is dismissed.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield")
                        .foregroundColor(.green)
                    Text("Security note: Target scripts must have execute permission (`chmod +x`). No user input or keystrokes are passed to scripts.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.green.opacity(0.08)))
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
    }
    
    // MARK: - Focus Modes Section
    
    private var focusModesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "moon.fill")
                    .foregroundColor(.indigo)
                Text("macOS Focus Modes")
                    .font(.headline)
            }
            
            Text("Break Reminder works smoothly with macOS Focus (Do Not Disturb, Work, Personal). You can set up an Apple Shortcut tied to Focus filter automation that calls 'Toggle Timer Pause' or 'Start Work Session' when your focus mode turns on.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func shortcutRow(title: String, description: String, phrase: String, action: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: "bolt.horizontal.fill")
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Phrase: \"\(phrase)\"")
                    .font(.caption2)
                    .foregroundColor(.accentColor)
            }
            
            Spacer()
            
            Button("Test") {
                action()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func notificationItem(name: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.primary)
            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}
