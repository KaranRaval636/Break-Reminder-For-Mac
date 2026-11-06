import Foundation

public struct DailyRecord: Codable, Identifiable, Equatable {
    public var id: String { dateIdentifier }
    public let dateIdentifier: String // yyyy-MM-dd
    public var completedWorkSessions: Int
    public var completedBreaks: Int
    public var skippedBreaks: Int
    public var workTimeSeconds: TimeInterval
    public var breakTimeSeconds: TimeInterval
    
    public init(
        dateIdentifier: String,
        completedWorkSessions: Int = 0,
        completedBreaks: Int = 0,
        skippedBreaks: Int = 0,
        workTimeSeconds: TimeInterval = 0,
        breakTimeSeconds: TimeInterval = 0
    ) {
        self.dateIdentifier = dateIdentifier
        self.completedWorkSessions = completedWorkSessions
        self.completedBreaks = completedBreaks
        self.skippedBreaks = skippedBreaks
        self.workTimeSeconds = workTimeSeconds
        self.breakTimeSeconds = breakTimeSeconds
    }
}

public struct AggregateStatistics: Equatable {
    public let totalCompletedWorkSessions: Int
    public let totalCompletedBreaks: Int
    public let totalSkippedBreaks: Int
    public let totalWorkTimeSeconds: TimeInterval
    public let totalBreakTimeSeconds: TimeInterval
    
    public init(
        totalCompletedWorkSessions: Int = 0,
        totalCompletedBreaks: Int = 0,
        totalSkippedBreaks: Int = 0,
        totalWorkTimeSeconds: TimeInterval = 0,
        totalBreakTimeSeconds: TimeInterval = 0
    ) {
        self.totalCompletedWorkSessions = totalCompletedWorkSessions
        self.totalCompletedBreaks = totalCompletedBreaks
        self.totalSkippedBreaks = totalSkippedBreaks
        self.totalWorkTimeSeconds = totalWorkTimeSeconds
        self.totalBreakTimeSeconds = totalBreakTimeSeconds
    }
}
