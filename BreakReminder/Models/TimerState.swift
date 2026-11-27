import Foundation

public enum TimerStatus: String, Codable, CaseIterable {
    case idle
    case working
    case paused
    case onBreak
    
    public var displayName: String {
        switch self {
        case .idle:
            return "Idle"
        case .working:
            return "Working"
        case .paused:
            return "Paused"
        case .onBreak:
            return "On Break"
        }
    }
    
    public var isWorking: Bool {
        self == .working
    }
    
    public var isOnBreak: Bool {
        self == .onBreak
    }
    
    public var isPaused: Bool {
        self == .paused
    }
    
    public var isIdle: Bool {
        self == .idle
    }
}

public enum BreakType: String, Codable {
    case shortBreak
    case longBreak
    
    public var displayName: String {
        switch self {
        case .shortBreak:
            return "Short Break"
        case .longBreak:
            return "Long Break"
        }
    }
}

public struct TimerSnapshot: Codable, Equatable {
    public var status: TimerStatus
    public var targetEndDate: Date?
    public var remainingSeconds: TimeInterval
    public var totalDurationSeconds: TimeInterval
    public var completedWorkSessionsInCycle: Int
    public var isLongBreak: Bool
    public var pausedRemainingSeconds: TimeInterval?
    public var lastSavedDate: Date
    public var sessionStartDate: Date?
    public var isBreakInBackground: Bool
    
    enum CodingKeys: String, CodingKey {
        case status
        case targetEndDate
        case remainingSeconds
        case totalDurationSeconds
        case completedWorkSessionsInCycle
        case isLongBreak
        case pausedRemainingSeconds
        case lastSavedDate
        case sessionStartDate
        case isBreakInBackground
    }
    
    public init(
        status: TimerStatus,
        targetEndDate: Date?,
        remainingSeconds: TimeInterval,
        totalDurationSeconds: TimeInterval,
        completedWorkSessionsInCycle: Int,
        isLongBreak: Bool,
        pausedRemainingSeconds: TimeInterval?,
        lastSavedDate: Date,
        sessionStartDate: Date? = nil,
        isBreakInBackground: Bool = false
    ) {
        self.status = status
        self.targetEndDate = targetEndDate
        self.remainingSeconds = remainingSeconds
        self.totalDurationSeconds = totalDurationSeconds
        self.completedWorkSessionsInCycle = completedWorkSessionsInCycle
        self.isLongBreak = isLongBreak
        self.pausedRemainingSeconds = pausedRemainingSeconds
        self.lastSavedDate = lastSavedDate
        self.sessionStartDate = sessionStartDate
        self.isBreakInBackground = isBreakInBackground
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decode(TimerStatus.self, forKey: .status)
        targetEndDate = try container.decodeIfPresent(Date.self, forKey: .targetEndDate)
        remainingSeconds = try container.decode(TimeInterval.self, forKey: .remainingSeconds)
        totalDurationSeconds = try container.decode(TimeInterval.self, forKey: .totalDurationSeconds)
        completedWorkSessionsInCycle = try container.decode(Int.self, forKey: .completedWorkSessionsInCycle)
        isLongBreak = try container.decode(Bool.self, forKey: .isLongBreak)
        pausedRemainingSeconds = try container.decodeIfPresent(TimeInterval.self, forKey: .pausedRemainingSeconds)
        lastSavedDate = try container.decode(Date.self, forKey: .lastSavedDate)
        sessionStartDate = try container.decodeIfPresent(Date.self, forKey: .sessionStartDate)
        isBreakInBackground = try container.decodeIfPresent(Bool.self, forKey: .isBreakInBackground) ?? false
    }
}
