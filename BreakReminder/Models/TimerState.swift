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
    
    public init(
        status: TimerStatus,
        targetEndDate: Date?,
        remainingSeconds: TimeInterval,
        totalDurationSeconds: TimeInterval,
        completedWorkSessionsInCycle: Int,
        isLongBreak: Bool,
        pausedRemainingSeconds: TimeInterval?,
        lastSavedDate: Date,
        sessionStartDate: Date? = nil
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
    }
}
