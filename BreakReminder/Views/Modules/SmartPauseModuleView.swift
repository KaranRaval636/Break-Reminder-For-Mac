import SwiftUI
import AppKit

public struct SmartPauseModuleView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var smartPauseManager: SmartPauseManager = .shared
    
    @State private var showingAddAppSheet: Bool = false
    @State private var newAppBundleId: String = ""
    @State private var newAppName: String = ""
    
    public init(
        settings: AppSettings = .shared,
        timerManager: TimerManager = .shared,
        smartPauseManager: SmartPauseManager = .shared
    ) {
        self.settings = settings
        self.timerManager = timerManager
        self.smartPauseManager = smartPauseManager
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Smart Pause")
                            .font(.system(size: 24, weight: .bold))
                        Text("Intelligently postpone breaks during meetings, presentations, and deep work.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("Enable Smart Pause", isOn: $settings.smartPauseEnabled)
                        .toggleStyle(.switch)
                }
                
                // Live Status Card
                liveStatusCard
                
                // Individual Detectors Card
                individualDetectorsCard
                
                // Excluded Focus Applications Card
                excludedApplicationsCard
                
                // Live Diagnostics & Debug Card
                diagnosticsCard
            }
            .padding(24)
        }
    }
    
    // MARK: - Live Status Card
    
    private var liveStatusCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 16) {
                Image(systemName: smartPauseManager.isSmartPaused ? "pause.circle.fill" : "checkmark.shield.fill")
                    .font(.system(size: 38))
                    .foregroundColor(smartPauseManager.isSmartPaused ? .orange : .green)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(smartPauseManager.isSmartPaused ? "Smart Pause Active" : "Smart Pause Monitoring")
                        .font(.headline)
                    
                    if let reason = smartPauseManager.primaryReasonText {
                        Text(reason)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    } else {
                        Text(settings.smartPauseEnabled ? "No delaying conditions detected. Scheduled breaks will trigger on time." : "Smart Pause is disabled in settings.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    smartPauseManager.evaluateNow()
                }) {
                    Label("Recheck Now", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }
            
            if !smartPauseManager.currentReasons.isEmpty {
                Divider()
                
                Text("Active Delay Reasons:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                ForEach(smartPauseManager.currentReasons) { reason in
                    HStack(spacing: 8) {
                        Image(systemName: reason.systemImage)
                            .foregroundColor(.orange)
                        Text(reason.title)
                            .fontWeight(.medium)
                        Text("— \(reason.detail)")
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                }
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(nsColor: .controlBackgroundColor)))
    }
    
    // MARK: - Individual Detectors Card
    
    private var individualDetectorsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detection Conditions")
                .font(.headline)
            
            // Idle Detection
            VStack(alignment: .leading, spacing: 6) {
                Toggle(isOn: $settings.smartPauseIdleEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("System Idle Detection")
                            .font(.body)
                            .fontWeight(.medium)
                        Text("Delays breaks when you are away from your desk so breaks aren't wasted")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if settings.smartPauseIdleEnabled {
                    HStack {
                        Text("Idle trigger threshold:")
                            .font(.subheadline)
                        Spacer()
                        Picker("", selection: $settings.smartPauseIdleThresholdSeconds) {
                            Text("1 minute").tag(60)
                            Text("2 minutes").tag(120)
                            Text("3 minutes").tag(180)
                            Text("5 minutes").tag(300)
                            Text("10 minutes").tag(600)
                        }
                        .frame(width: 140)
                    }
                    .padding(.leading, 24)
                }
            }
            
            Divider()
            
            // Fullscreen Detection
            Toggle(isOn: $settings.smartPauseFullscreenEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Full-Screen Application Detection")
                        .font(.body)
                        .fontWeight(.medium)
                    Text("Suppresses break overlay when frontmost app is running in full-screen")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Meeting Detection
            Toggle(isOn: $settings.smartPauseMeetingEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Meeting & Video Call Detection")
                        .font(.body)
                        .fontWeight(.medium)
                    Text("Postpones breaks during Zoom, Microsoft Teams, Google Meet, Webex and FaceTime")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Screen Recording Detection
            Toggle(isOn: $settings.smartPauseRecordingEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Screen Recording & Broadcasting Detection")
                        .font(.body)
                        .fontWeight(.medium)
                    Text("Prevents interruptions while recording or streaming (OBS Studio, QuickTime, Loom)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Video Playback Detection
            Toggle(isOn: $settings.smartPauseVideoEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Video Playback Detection")
                        .font(.body)
                        .fontWeight(.medium)
                    Text("Delays breaks while actively viewing video in QuickTime, VLC, IINA or Apple TV")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Postpone Buffer
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Postpone Grace Buffer")
                        .font(.body)
                        .fontWeight(.medium)
                    Text("Time granted after a meeting/call ends before the delayed break appears")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Picker("", selection: $settings.smartPausePostponeBufferSeconds) {
                    Text("30 seconds").tag(30)
                    Text("1 minute").tag(60)
                    Text("2 minutes").tag(120)
                }
                .frame(width: 140)
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(nsColor: .controlBackgroundColor)))
    }
    
    // MARK: - Excluded Applications Card
    
    private var excludedApplicationsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Focus Application Exclusions")
                        .font(.headline)
                    Text("Breaks are postponed when any of these apps are currently frontmost.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    showingAddAppSheet = true
                }) {
                    Label("Add Application", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.bordered)
            }
            
            Toggle("Enable Focus App exclusions", isOn: $settings.smartPauseFocusAppsEnabled)
                .font(.subheadline)
            
            if settings.excludedApps.isEmpty {
                Text("No applications excluded. Click 'Add Application' to specify apps that delay breaks.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 6) {
                    ForEach(settings.excludedApps) { app in
                        HStack {
                            Image(systemName: "app.dashed")
                                .foregroundColor(.accentColor)
                            Text(app.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("(\(app.bundleIdentifier))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button(action: {
                                smartPauseManager.removeExcludedApp(id: app.bundleIdentifier)
                            }) {
                                Image(systemName: "trash")
                                    .font(.caption)
                                    .foregroundColor(.red.opacity(0.8))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .windowBackgroundColor)))
                    }
                }
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(nsColor: .controlBackgroundColor)))
        .sheet(isPresented: $showingAddAppSheet) {
            addApplicationSheet
        }
    }
    
    // MARK: - Add Application Sheet
    
    private var addApplicationSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Excluded Application")
                .font(.headline)
            
            Text("Select from currently running applications or enter a bundle identifier:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Running Apps Quick Picker
            ScrollView {
                VStack(spacing: 6) {
                    let running = NSWorkspace.shared.runningApplications
                        .filter { $0.activationPolicy == .regular && $0.bundleIdentifier != Bundle.main.bundleIdentifier }
                    
                    ForEach(running, id: \.processIdentifier) { app in
                        Button(action: {
                            if let bundleId = app.bundleIdentifier {
                                smartPauseManager.addExcludedApp(
                                    bundleIdentifier: bundleId,
                                    name: app.localizedName ?? bundleId
                                )
                                showingAddAppSheet = false
                            }
                        }) {
                            HStack {
                                if let icon = app.icon {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                }
                                Text(app.localizedName ?? "App")
                                    .font(.subheadline)
                                Spacer()
                                Text(app.bundleIdentifier ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color(nsColor: .controlBackgroundColor)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 200)
            
            Divider()
            
            // Manual Entry
            HStack(spacing: 10) {
                TextField("App Name (e.g. Figma)", text: $newAppName)
                    .textFieldStyle(.roundedBorder)
                TextField("Bundle ID (e.g. com.figma.Desktop)", text: $newAppBundleId)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Spacer()
                Button("Cancel") {
                    showingAddAppSheet = false
                }
                .buttonStyle(.bordered)
                
                Button("Add Custom App") {
                    if !newAppBundleId.isEmpty {
                        smartPauseManager.addExcludedApp(
                            bundleIdentifier: newAppBundleId,
                            name: newAppName.isEmpty ? newAppBundleId : newAppName
                        )
                        newAppName = ""
                        newAppBundleId = ""
                        showingAddAppSheet = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(newAppBundleId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 480, height: 380)
    }
    
    // MARK: - Diagnostics Card
    
    private var diagnosticsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Smart Pause Diagnostics (Real-time)")
                .font(.headline)
            
            Text("Live status of all detection subsystems:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                ForEach(smartPauseManager.diagnostics) { diag in
                    HStack(alignment: .top) {
                        Circle()
                            .fill(diag.isTriggered ? Color.orange : (diag.isEnabled ? Color.green : Color.secondary))
                            .frame(width: 8, height: 8)
                            .padding(.top, 4)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(diag.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(diag.details)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color(nsColor: .windowBackgroundColor)))
                }
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(nsColor: .controlBackgroundColor)))
    }
}
