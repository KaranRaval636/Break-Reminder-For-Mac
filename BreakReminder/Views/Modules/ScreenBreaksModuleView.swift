import SwiftUI

public struct ScreenBreaksModuleView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var timerManager: TimerManager
    
    public init(settings: AppSettings = .shared, timerManager: TimerManager = .shared) {
        self.settings = settings
        self.timerManager = timerManager
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Screen Breaks")
                        .font(.system(size: 24, weight: .bold))
                    Text("Configure your focus cycles, break intervals, and profile presets.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Break Profiles Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Break Profile")
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(BreakProfile.allCases) { profile in
                            profileCard(profile)
                        }
                    }
                }
                
                Divider()
                
                // Durations & Intervals
                VStack(alignment: .leading, spacing: 18) {
                    Text("Interval Durations")
                        .font(.headline)
                    
                    durationRow(
                        title: "Work Session",
                        subtitle: "Uninterrupted focus duration before a break",
                        value: "\(settings.workIntervalMinutes) min",
                        binding: Binding(
                            get: { Double(settings.workIntervalMinutes) },
                            set: {
                                settings.workIntervalMinutes = Int($0)
                                if settings.breakProfile != .custom {
                                    settings.breakProfile = .custom
                                }
                            }
                        ),
                        range: Double(AppSettings.minWorkMinutes)...Double(AppSettings.maxWorkMinutes),
                        step: 5
                    )
                    
                    durationRow(
                        title: "Short Break",
                        subtitle: "Quick rest between standard focus sessions",
                        value: "\(settings.shortBreakMinutes) min",
                        binding: Binding(
                            get: { Double(settings.shortBreakMinutes) },
                            set: {
                                settings.shortBreakMinutes = Int($0)
                                if settings.breakProfile != .custom {
                                    settings.breakProfile = .custom
                                }
                            }
                        ),
                        range: Double(AppSettings.minBreakMinutes)...Double(AppSettings.maxBreakMinutes),
                        step: 1
                    )
                    
                    durationRow(
                        title: "Long Break",
                        subtitle: "Extended rest to recharge your mind and body",
                        value: "\(settings.longBreakMinutes) min",
                        binding: Binding(
                            get: { Double(settings.longBreakMinutes) },
                            set: {
                                settings.longBreakMinutes = Int($0)
                                if settings.breakProfile != .custom {
                                    settings.breakProfile = .custom
                                }
                            }
                        ),
                        range: Double(AppSettings.minBreakMinutes)...Double(AppSettings.maxBreakMinutes),
                        step: 5
                    )
                    
                    durationRow(
                        title: "Long Break Frequency",
                        subtitle: "Number of work sessions before triggering a long break",
                        value: "Every \(settings.longBreakFrequency) sessions",
                        binding: Binding(
                            get: { Double(settings.longBreakFrequency) },
                            set: {
                                settings.longBreakFrequency = Int($0)
                                if settings.breakProfile != .custom {
                                    settings.breakProfile = .custom
                                }
                            }
                        ),
                        range: Double(AppSettings.minFrequency)...Double(AppSettings.maxFrequency),
                        step: 1
                    )
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
                
                Divider()
                
                // Break Flow & Behavior
                VStack(alignment: .leading, spacing: 14) {
                    Text("Break Behavior & Controls")
                        .font(.headline)
                    
                    Toggle(isOn: $settings.autoStartBreaks) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Automatically start breaks")
                                .font(.body)
                            Text("When work interval completes, immediately show full-screen overlay")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Toggle(isOn: $settings.autoStartWorkTimer) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Automatically resume work after break")
                                .font(.body)
                            Text("Begin next focus session as soon as break finishes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Toggle(isOn: $settings.allowSnooze) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Allow snoozing breaks")
                                .font(.body)
                            Text("Postpone break by a configurable amount of time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if settings.allowSnooze {
                        HStack {
                            Text("Snooze duration:")
                                .font(.subheadline)
                            Spacer()
                            Picker("", selection: $settings.snoozeDurationMinutes) {
                                Text("2 minutes").tag(2)
                                Text("3 minutes").tag(3)
                                Text("5 minutes").tag(5)
                                Text("10 minutes").tag(10)
                            }
                            .frame(width: 130)
                        }
                        
                        HStack {
                            Text("Max snoozes per break:")
                                .font(.subheadline)
                            Spacer()
                            Picker("", selection: $settings.snoozeLimit) {
                                Text("Unlimited").tag(0)
                                Text("1 snooze").tag(1)
                                Text("2 snoozes").tag(2)
                                Text("3 snoozes").tag(3)
                                Text("5 snoozes").tag(5)
                            }
                            .frame(width: 130)
                        }
                    }
                    
                    Toggle(isOn: $settings.allowSkip) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Allow skipping breaks")
                                .font(.body)
                            Text("Permits dismissing a break immediately")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Toggle(isOn: $settings.allowScreenAccessDuringBreak) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Allow accessing screen during breaks")
                                .font(.body)
                            Text("Allows continuing the break in the background while using your screen")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Toggle(isOn: $settings.strictMode) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Strict Mode (Enforced Breaks)")
                                .font(.body)
                            Text("Disables Skip, Snooze, and Access Screen buttons during breaks")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
                
                Divider()
                
                // Pre-break alerts & Messages
                VStack(alignment: .leading, spacing: 14) {
                    Text("Pre-break Alerts & Custom Messages")
                        .font(.headline)
                    
                    Toggle(isOn: $settings.preBreakNotificationEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pre-break warning notification")
                                .font(.body)
                            Text("Receive a gentle notification right before your break begins")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if settings.preBreakNotificationEnabled {
                        HStack {
                            Text("Notify before:")
                                .font(.subheadline)
                            Spacer()
                            Picker("", selection: $settings.preBreakNotificationLeadMinutes) {
                                Text("1 minute before").tag(1)
                                Text("2 minutes before").tag(2)
                                Text("3 minutes before").tag(3)
                                Text("5 minutes before").tag(5)
                            }
                            .frame(width: 160)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Break Screen Title")
                            .font(.subheadline)
                        TextField("Break title", text: $settings.customBreakTitle)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Break Screen Subtitle")
                            .font(.subheadline)
                        TextField("Break subtitle", text: $settings.customBreakSubtitle)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
            }
            .padding(24)
        }
    }
    
    @ViewBuilder
    private func profileCard(_ profile: BreakProfile) -> some View {
        let isSelected = settings.breakProfile == profile
        Button(action: {
            settings.applyProfile(profile)
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: profile.systemImage)
                        .font(.title2)
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                }
                
                Text(profile.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(profile.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func durationRow(title: String, subtitle: String, value: String, binding: Binding<Double>, range: ClosedRange<Double>, step: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(value)
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.accentColor.opacity(0.1)))
            }
            
            Slider(value: binding, in: range, step: step)
        }
    }
}
