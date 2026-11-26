import Foundation

public struct DailyRecord: Codable, Identifiable, Equatable {
    public var id: String { dateIdentifier }
    public let dateIdentifier: String // yyyy-MM-dd
    public var completedWorkSessions: Int
    public var completedBreaks: Int
    public var skippedBreaks: Int
    public var workTimeSeconds: TimeInterval
    public var breakTimeSeconds: TimeInterval
    public var naturalBreaks: Int
    public var longestWorkSessionSeconds: TimeInterval
    
    public init(
        dateIdentifier: String,
        completedWorkSessions: Int = 0,
        completedBreaks: Int = 0,
        skippedBreaks: Int = 0,
        workTimeSeconds: TimeInterval = 0,
        breakTimeSeconds: TimeInterval = 0,
        naturalBreaks: Int = 0,
        longestWorkSessionSeconds: TimeInterval = 0
    ) {
        self.dateIdentifier = dateIdentifier
        self.completedWorkSessions = completedWorkSessions
        self.completedBreaks = completedBreaks
        self.skippedBreaks = skippedBreaks
        self.workTimeSeconds = workTimeSeconds
        self.breakTimeSeconds = breakTimeSeconds
        self.naturalBreaks = naturalBreaks
        self.longestWorkSessionSeconds = longestWorkSessionSeconds
    }
    
    public var averageWorkSessionSeconds: TimeInterval {
        guard completedWorkSessions > 0 else { return workTimeSeconds }
        return workTimeSeconds / Double(completedWorkSessions)
    }
    
    public var averageBreakDurationSeconds: TimeInterval {
        let total = completedBreaks + naturalBreaks
        guard total > 0 else { return 0 }
        return breakTimeSeconds / Double(total)
    }
    
    public var complianceRate: Double {
        let total = completedBreaks + skippedBreaks
        guard total > 0 else { return 1.0 }
        return Double(completedBreaks) / Double(total)
    }
    
    enum CodingKeys: String, CodingKey {
        case dateIdentifier
        case completedWorkSessions
        case completedBreaks
        case skippedBreaks
        case workTimeSeconds
        case breakTimeSeconds
        case naturalBreaks
        case longestWorkSessionSeconds
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.dateIdentifier = try container.decode(String.self, forKey: .dateIdentifier)
        self.completedWorkSessions = try container.decodeIfPresent(Int.self, forKey: .completedWorkSessions) ?? 0
        self.completedBreaks = try container.decodeIfPresent(Int.self, forKey: .completedBreaks) ?? 0
        self.skippedBreaks = try container.decodeIfPresent(Int.self, forKey: .skippedBreaks) ?? 0
        self.workTimeSeconds = try container.decodeIfPresent(TimeInterval.self, forKey: .workTimeSeconds) ?? 0
        self.breakTimeSeconds = try container.decodeIfPresent(TimeInterval.self, forKey: .breakTimeSeconds) ?? 0
        self.naturalBreaks = try container.decodeIfPresent(Int.self, forKey: .naturalBreaks) ?? 0
        self.longestWorkSessionSeconds = try container.decodeIfPresent(TimeInterval.self, forKey: .longestWorkSessionSeconds) ?? 0
    }
}

public struct AggregateStatistics: Equatable {
    public let totalCompletedWorkSessions: Int
    public let totalCompletedBreaks: Int
    public let totalSkippedBreaks: Int
    public let totalWorkTimeSeconds: TimeInterval
    public let totalBreakTimeSeconds: TimeInterval
    public let totalNaturalBreaks: Int
    public let longestWorkSessionSeconds: TimeInterval
    public let averageWorkSessionSeconds: TimeInterval
    public let averageBreakDurationSeconds: TimeInterval
    
    public init(
        totalCompletedWorkSessions: Int = 0,
        totalCompletedBreaks: Int = 0,
        totalSkippedBreaks: Int = 0,
        totalWorkTimeSeconds: TimeInterval = 0,
        totalBreakTimeSeconds: TimeInterval = 0,
        totalNaturalBreaks: Int = 0,
        longestWorkSessionSeconds: TimeInterval = 0,
        averageWorkSessionSeconds: TimeInterval = 0,
        averageBreakDurationSeconds: TimeInterval = 0
    ) {
        self.totalCompletedWorkSessions = totalCompletedWorkSessions
        self.totalCompletedBreaks = totalCompletedBreaks
        self.totalSkippedBreaks = totalSkippedBreaks
        self.totalWorkTimeSeconds = totalWorkTimeSeconds
        self.totalBreakTimeSeconds = totalBreakTimeSeconds
        self.totalNaturalBreaks = totalNaturalBreaks
        self.longestWorkSessionSeconds = longestWorkSessionSeconds
        self.averageWorkSessionSeconds = averageWorkSessionSeconds
        self.averageBreakDurationSeconds = averageBreakDurationSeconds
    }
}
