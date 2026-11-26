import SwiftUI

public struct WellnessModuleView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var wellnessManager: WellnessReminderManager = .shared
    
    public init(settings: AppSettings = .shared, wellnessManager: WellnessReminderManager = .shared) {
        self.settings = settings
        self.wellnessManager = wellnessManager
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Wellness Reminders")
                        .font(.system(size: 24, weight: .bold))
                    Text("Lightweight, independent periodic micro-nudges for eye rest and posture alignment.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Blink Reminders Card
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "eye.fill")
                            .font(.title2)
                            .foregroundColor(.teal)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Blink & Eye Rest Reminders (20-20-20 Rule)")
                                .font(.headline)
                            Text("Promote natural blinking and distance gazing to avoid digital eye strain.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            wellnessManager.triggerBlinkReminderNow()
                        }) {
                            Label("Test Nudge", systemImage: "bell.badge")
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Toggle("Enable periodic eye rest reminders", isOn: $settings.blinkRemindersEnabled)
                    
                    if settings.blinkRemindersEnabled {
                        HStack {
                            Text("Reminder Frequency:")
                                .font(.subheadline)
                            Spacer()
                            Picker("", selection: $settings.blinkReminderIntervalMinutes) {
                                Text("Every 10 minutes").tag(10)
                                Text("Every 15 minutes").tag(15)
                                Text("Every 20 minutes (Recommended)").tag(20)
                                Text("Every 30 minutes").tag(30)
                            }
                            .frame(width: 250)
                        }
                        
                        Toggle("Play gentle sound on notification", isOn: $settings.blinkSoundEnabled)
                            .font(.subheadline)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Custom Reminder Message:")
                                .font(.subheadline)
                            TextField("Blink message", text: $settings.blinkCustomMessage)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(nsColor: .controlBackgroundColor)))
                
                // Posture Reminders Card
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "figure.walk")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Posture & Ergonomics Reminders")
                                .font(.headline)
                            Text("Gentle reminders to realign spine, drop shoulders, and adjust chair elevation.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            wellnessManager.triggerPostureReminderNow()
                        }) {
                            Label("Test Nudge", systemImage: "bell.badge")
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Toggle("Enable posture alerts", isOn: $settings.postureRemindersEnabled)
                    
                    if settings.postureRemindersEnabled {
                        HStack {
                            Text("Reminder Frequency:")
                                .font(.subheadline)
                            Spacer()
                            Picker("", selection: $settings.postureReminderIntervalMinutes) {
                                Text("Every 20 minutes").tag(20)
                                Text("Every 30 minutes").tag(30)
                                Text("Every 45 minutes (Recommended)").tag(45)
                                Text("Every 60 minutes").tag(60)
                            }
                            .frame(width: 250)
                        }
                        
                        Toggle("Play gentle sound on notification", isOn: $settings.postureSoundEnabled)
                            .font(.subheadline)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Custom Posture Message:")
                                .font(.subheadline)
                            TextField("Posture message", text: $settings.postureCustomMessage)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(nsColor: .controlBackgroundColor)))
                
                // Natural Break Settings Card
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "cup.and.saucer")
                            .font(.title2)
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Natural Break Detection")
                                .font(.headline)
                            Text("Automatically credits away-from-desk time toward your rest without repetitive popups.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Toggle("Enable idle-based natural break detection", isOn: $settings.naturalBreakEnabled)
                    
                    if settings.naturalBreakEnabled {
                        HStack {
                            Text("Minimum away time to qualify as rest:")
                                .font(.subheadline)
                            Spacer()
                            Picker("", selection: $settings.naturalBreakThresholdSeconds) {
                                Text("3 minutes").tag(180)
                                Text("5 minutes (Recommended)").tag(300)
                                Text("10 minutes").tag(600)
                                Text("15 minutes").tag(900)
                            }
                            .frame(width: 220)
                        }
                    }
                }
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(nsColor: .controlBackgroundColor)))
            }
            .padding(24)
        }
    }
}
