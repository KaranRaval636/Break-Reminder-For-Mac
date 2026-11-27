import SwiftUI

public struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var timerManager: TimerManager
    
    @State private var launchAtLoginError: String?
    @State private var showingResetAlert = false
    
    public init(settings: AppSettings = .shared, timerManager: TimerManager = .shared) {
        self.settings = settings
        self.timerManager = timerManager
    }
    
    public var body: some View {
        TabView {
            timerSettingsTab
                .tabItem {
                    Label("Timers", systemImage: "clock")
                }
            
            breakBehaviorTab
                .tabItem {
                    Label("Break Behavior", systemImage: "sparkles")
                }
            
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
        }
        .padding(20)
        .frame(width: 520, height: 440)
        .preferredColorScheme(settings.theme.colorScheme)
        .alert("Reset Settings to Defaults?", isPresented: $showingResetAlert) {
            Button("Reset", role: .destructive) {
                settings.restoreDefaults()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reset all timers, break options, and general settings back to their factory default values.")
        }
    }
    
    // MARK: - Tab A: Timer Settings
    
    private var timerSettingsTab: some View {
        Form {
            Section(header: Text("Interval Durations").font(.headline)) {
                // Work interval
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Work Interval:")
                        Spacer()
                        Text("\(settings.workIntervalMinutes) minutes")
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    Slider(
                        value: Binding(
                            get: { Double(settings.workIntervalMinutes) },
                            set: { settings.workIntervalMinutes = Int($0) }
                        ),
                        in: Double(AppSettings.minWorkMinutes)...Double(AppSettings.maxWorkMinutes),
                        step: 5
                    )
                }
                .padding(.vertical, 4)
                
                // Short break duration
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Short Break:")
                        Spacer()
                        Text("\(settings.shortBreakMinutes) minutes")
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    Slider(
                        value: Binding(
                            get: { Double(settings.shortBreakMinutes) },
                            set: { settings.shortBreakMinutes = Int($0) }
                        ),
                        in: Double(AppSettings.minBreakMinutes)...Double(AppSettings.maxBreakMinutes),
                        step: 1
                    )
                }
                .padding(.vertical, 4)
                
                // Long break duration
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Long Break:")
                        Spacer()
                        Text("\(settings.longBreakMinutes) minutes")
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    Slider(
                        value: Binding(
                            get: { Double(settings.longBreakMinutes) },
                            set: { settings.longBreakMinutes = Int($0) }
                        ),
                        in: Double(AppSettings.minBreakMinutes)...Double(AppSettings.maxBreakMinutes),
                        step: 1
                    )
                }
                .padding(.vertical, 4)
                
                // Long break frequency
                Stepper(
                    "Long Break Frequency: every \(settings.longBreakFrequency) sessions",
                    value: $settings.longBreakFrequency,
                    in: AppSettings.minFrequency...AppSettings.maxFrequency
                )
                .padding(.vertical, 4)
            }
        }
        .formStyle(.grouped)
    }
    
    // MARK: - Tab B: Break Behaviour
    
    private var breakBehaviorTab: some View {
        Form {
            Section(header: Text("Automation & Overlays").font(.headline)) {
                Toggle("Enable automatic breaks after work session", isOn: $settings.autoStartBreaks)
                
                Toggle("Show break overlay on all displays", isOn: $settings.allDisplays)
                    .help("When checked, all connected monitors are covered with the wellness screen.")
                
                Toggle("Allow accessing screen during break", isOn: $settings.allowScreenAccessDuringBreak)
                    .help("Allows continuing the break in the background while using your screen.")
            }
            
            Section(header: Text("Snooze Options").font(.headline)) {
                Toggle("Enable snooze during breaks", isOn: $settings.allowSnooze)
                
                if settings.allowSnooze {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Snooze Duration:")
                            Spacer()
                            Text("\(settings.snoozeDurationMinutes) minutes")
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                        Slider(
                            value: Binding(
                                get: { Double(settings.snoozeDurationMinutes) },
                                set: { settings.snoozeDurationMinutes = Int($0) }
                            ),
                            in: Double(AppSettings.minSnoozeMinutes)...Double(AppSettings.maxSnoozeMinutes),
                            step: 1
                        )
                    }
                    .padding(.vertical, 2)
                }
            }
            
            Section(header: Text("Alerts & Sounds").font(.headline)) {
                Toggle("Enable sound chimes", isOn: $settings.soundEnabled)
                Toggle("Enable system notifications", isOn: $settings.notificationsEnabled)
            }
        }
        .formStyle(.grouped)
    }
    
    // MARK: - Tab C: General
    
    private var generalTab: some View {
        Form {
            Section(header: Text("App Launch & Behavior").font(.headline)) {
                Toggle("Launch Break Reminder at login", isOn: Binding(
                    get: { settings.launchAtLogin },
                    set: { newValue in
                        settings.launchAtLogin = newValue
                        let result = LaunchAtLoginManager.shared.setEnabled(newValue)
                        switch result {
                        case .success:
                            launchAtLoginError = nil
                        case .failure(let err):
                            launchAtLoginError = err.localizedDescription
                        }
                    }
                ))
                
                if let err = launchAtLoginError {
                    Text("Launch at login note: \(err)")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Toggle("Start work timer automatically on launch", isOn: $settings.autoStartWorkTimer)
            }
            
            Section(header: Text("Appearance").font(.headline)) {
                Picker("Theme:", selection: $settings.theme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section {
                Button(role: .destructive, action: {
                    showingResetAlert = true
                }) {
                    Text("Restore Default Settings")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .formStyle(.grouped)
    }
}
