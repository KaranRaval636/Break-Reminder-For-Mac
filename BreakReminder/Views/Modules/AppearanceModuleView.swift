import SwiftUI
import AppKit

public struct AppearanceModuleView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var timerManager: TimerManager
    @State private var showingLivePreview: Bool = false
    
    public init(settings: AppSettings = .shared, timerManager: TimerManager = .shared) {
        self.settings = settings
        self.timerManager = timerManager
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Appearance & Customization")
                            .font(.system(size: 24, weight: .bold))
                        Text("Personalize themes, animated backgrounds, audio tones, and HUD countdown.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showingLivePreview = true
                    }) {
                        Label("Preview Break Screen", systemImage: "eye.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                // Theme Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Application Theme")
                        .font(.headline)
                    
                    Picker("", selection: $settings.theme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 340)
                }
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
                
                // Break Background Visuals Card
                VStack(alignment: .leading, spacing: 14) {
                    Text("Break Screen Background Style")
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        backgroundStyleCard(
                            id: "aurora",
                            title: "Aurora Ambient",
                            description: "Gently shifting fluid gradient blobs",
                            colors: [.teal, .blue, .black]
                        )
                        backgroundStyleCard(
                            id: "gradient",
                            title: "Gradient Mesh",
                            description: "Vibrant deep indigo and teal mesh",
                            colors: [.indigo, .teal, .black]
                        )
                        backgroundStyleCard(
                            id: "dark",
                            title: "Deep Minimalist Dark",
                            description: "Ultra-dark calm OLED slate",
                            colors: [.black, Color(white: 0.1)]
                        )
                        backgroundStyleCard(
                            id: "light",
                            title: "Soft Daylight Light",
                            description: "Gentle daylight aesthetic",
                            colors: [Color(white: 0.95), Color(white: 0.85)]
                        )
                    }
                }
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
                
                // Audio & Chimes Card
                VStack(alignment: .leading, spacing: 14) {
                    Text("Audio Chimes")
                        .font(.headline)
                    
                    Toggle("Enable audio chimes on session completion", isOn: $settings.soundEnabled)
                    
                    if settings.soundEnabled {
                        HStack(spacing: 12) {
                            Text("Chime Sound:")
                                .font(.subheadline)
                            
                            Picker("", selection: $settings.soundName) {
                                ForEach(WellnessSoundPreset.allCases) { preset in
                                    Text(preset.displayName).tag(preset.rawValue)
                                }
                            }
                            .frame(maxWidth: 260)
                            
                            Button(action: {
                                if let preset = WellnessSoundPreset(rawValue: settings.soundName) {
                                    SoundManager.shared.playPreview(preset: preset)
                                }
                            }) {
                                Label("Test Sound", systemImage: "speaker.wave.2.fill")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
                
                // Mindful Breathing Guide Card
                VStack(alignment: .leading, spacing: 14) {
                    Text("Mindful Breathing Guide")
                        .font(.headline)
                    
                    Toggle(isOn: $settings.breathingGuideEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Enable 4-4-4 Box Breathing on break screen")
                                .font(.body)
                            Text("Provides an expanding and contracting visual rhythm to relax your nervous system")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
                
                // Floating Countdown HUD Card
                VStack(alignment: .leading, spacing: 14) {
                    Text("Floating Countdown HUD")
                        .font(.headline)
                    
                    Toggle(isOn: $settings.floatingCountdownEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Enable compact Floating Countdown HUD")
                                .font(.body)
                            Text("A draggable, translucent pill showing remaining focus time on your desktop")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if settings.floatingCountdownEnabled {
                        HStack {
                            Text("Default Screen Position:")
                                .font(.subheadline)
                            Spacer()
                            Picker("", selection: $settings.floatingPosition) {
                                Text("Top Right").tag("topRight")
                                Text("Top Left").tag("topLeft")
                                Text("Bottom Right").tag("bottomRight")
                                Text("Bottom Left").tag("bottomLeft")
                            }
                            .frame(width: 170)
                        }
                        
                        Toggle("Only show HUD during pre-break alert window", isOn: $settings.floatingOnlyInPreBreak)
                            .font(.subheadline)
                    }
                }
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
            }
            .padding(24)
        }
        .sheet(isPresented: $showingLivePreview) {
            ZStack(alignment: .topTrailing) {
                BreakScreenView(timerManager: timerManager, appSettings: settings)
                    .frame(minWidth: 700, minHeight: 500)
                
                Button(action: {
                    showingLivePreview = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(20)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    @ViewBuilder
    private func backgroundStyleCard(id: String, title: String, description: String, colors: [Color]) -> some View {
        let isSelected = settings.backgroundStyle == id
        Button(action: {
            settings.backgroundStyle = id
        }) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 44, height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .windowBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
