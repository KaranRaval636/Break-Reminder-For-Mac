import SwiftUI
import AppKit

public struct FloatingCountdownView: View {
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var settings: AppSettings
    
    @State private var isHovered: Bool = false
    
    public init(timerManager: TimerManager = .shared, settings: AppSettings = .shared) {
        self.timerManager = timerManager
        self.settings = settings
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            // Pulse Dot
            Circle()
                .fill(statusDotColor)
                .frame(width: 8, height: 8)
            
            // Countdown Text
            VStack(alignment: .leading, spacing: 1) {
                Text(DateHelpers.formatRemainingTime(timerManager.remainingSeconds))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer(minLength: 4)
            
            // Quick hover actions
            if isHovered {
                if timerManager.canSnooze {
                    Button(action: {
                        timerManager.snoozeBreak()
                    }) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 12))
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                    .help("Quick Snooze (+5m)")
                }
                
                Button(action: {
                    settings.floatingCountdownEnabled = false
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Hide Floating HUD")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(width: 154, height: 38)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
    
    private var statusDotColor: Color {
        if timerManager.remainingSeconds <= TimeInterval(settings.preBreakNotificationLeadMinutes * 60) {
            return .orange
        }
        return .green
    }
    
    private var subtitle: String {
        if timerManager.remainingSeconds <= TimeInterval(settings.preBreakNotificationLeadMinutes * 60) {
            return "Break soon"
        }
        return "Focusing"
    }
}
