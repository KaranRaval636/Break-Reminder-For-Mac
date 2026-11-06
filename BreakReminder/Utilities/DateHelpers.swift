import Foundation

public enum DateHelpers {
    public static func formatRemainingTime(_ seconds: TimeInterval) -> String {
        let clamped = max(0, Int(seconds.rounded(.up)))
        let hours = clamped / 3600
        let minutes = (clamped % 3600) / 60
        let secs = clamped % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
    
    public static func formatDurationDetailed(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int(seconds) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    public static func dayIdentifier(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    public static func displayDateString(from identifier: String) -> String {
        let parser = DateFormatter()
        parser.calendar = Calendar.current
        parser.dateFormat = "yyyy-MM-dd"
        
        guard let date = parser.date(from: identifier) else {
            return identifier
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.calendar = Calendar.current
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .none
        return displayFormatter.string(from: date)
    }
}
