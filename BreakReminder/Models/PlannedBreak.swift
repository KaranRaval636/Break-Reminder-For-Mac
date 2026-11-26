import Foundation

public struct PlannedBreak: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var hour: Int
    public var minute: Int
    public var durationMinutes: Int
    public var repeatDays: [Int] // 1 = Sunday, 2 = Monday, ..., 7 = Saturday
    public var isEnabled: Bool
    public var customMessage: String
    public var soundEnabled: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        hour: Int,
        minute: Int,
        durationMinutes: Int,
        repeatDays: [Int] = [2, 3, 4, 5, 6], // Mon - Fri
        isEnabled: Bool = true,
        customMessage: String = "Scheduled break time. Step away and refresh!",
        soundEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.hour = hour
        self.minute = minute
        self.durationMinutes = durationMinutes
        self.repeatDays = repeatDays
        self.isEnabled = isEnabled
        self.customMessage = customMessage
        self.soundEnabled = soundEnabled
    }
    
    public var formattedTime: String {
        let dateComponents = DateComponents(hour: hour, minute: minute)
        if let date = Calendar.current.date(from: dateComponents) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        return String(format: "%02d:%02d", hour, minute)
    }
    
    public func isActiveOn(weekday: Int) -> Bool {
        return repeatDays.contains(weekday)
    }
    
    public var formattedDuration: String {
        return "\(durationMinutes)m"
    }
    
    public var repeatDaysDescription: String {
        let set = Set(repeatDays)
        if set == Set([1, 2, 3, 4, 5, 6, 7]) {
            return "Every Day"
        } else if set == Set([2, 3, 4, 5, 6]) {
            return "Weekdays (Mon - Fri)"
        } else if set == Set([1, 7]) {
            return "Weekends"
        } else {
            let names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            let active = repeatDays.sorted().compactMap { day -> String? in
                guard day >= 1 && day <= 7 else { return nil }
                return names[day - 1]
            }
            return active.joined(separator: ", ")
        }
    }
}
