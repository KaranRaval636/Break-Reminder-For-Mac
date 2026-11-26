import SwiftUI

public struct GeneralSettingsModuleView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var timerManager: TimerManager
    @State private var showingResetAlert = false
    
    public init(settings: AppSettings = .shared, timerManager: TimerManager = .shared) {
        self.settings = settings
        self.timerManager = timerManager
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("General Settings")
                        .font(.system(size: 24, weight: .bold))
                    Text("Configure system integration, launch options, notifications and display targets.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 14) {
                    Text("System & Startup")
                        .font(.headline)
                    
                    Toggle("Launch Break Reminder at login", isOn: $settings.launchAtLogin)
                    Toggle("Enable macOS Notification Center banners", isOn: $settings.notificationsEnabled)
                    Toggle("Show break overlay across all connected displays", isOn: $settings.allDisplays)
                }
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
                
                VStack(alignment: .leading, spacing: 14) {
                    Text("Privacy & Data")
                        .font(.headline)
                    Text("Break Reminder runs 100% locally on your Mac. No accounts, no network analytics, no screenshots, and no keystrokes are ever recorded.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    Button("Reset All Settings to Factory Defaults", role: .destructive) {
                        showingResetAlert = true
                    }
                    .buttonStyle(.bordered)
                }
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
            }
            .padding(24)
        }
        .alert("Reset Settings to Defaults?", isPresented: $showingResetAlert) {
            Button("Reset", role: .destructive) {
                settings.restoreDefaults()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will restore all timer intervals, break profiles, and preferences back to default values.")
        }
    }
}
