import Foundation
import Combine

public protocol StatisticsManaging: AnyObject {
    var records: [DailyRecord] { get }
    var aggregate: AggregateStatistics { get }
    func recordWorkSessionCompleted(duration: TimeInterval)
    func recordBreakCompleted(duration: TimeInterval)
    func recordBreakSkipped()
    func recordWorkTime(seconds: TimeInterval)
    func recordBreakTime(seconds: TimeInterval)
    func clearAll()
}

public final class StatisticsManager: ObservableObject, StatisticsManaging {
    public static let shared = StatisticsManager()
    
    private let userDefaults: UserDefaults
    private let storageKey = "BreakReminder_DailyRecords_v1"
    
    @Published public private(set) var records: [DailyRecord] = []
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadRecords()
    }
    
    public var aggregate: AggregateStatistics {
        let totalSessions = records.reduce(0) { $0 + $1.completedWorkSessions }
        let totalBreaks = records.reduce(0) { $0 + $1.completedBreaks }
        let totalSkipped = records.reduce(0) { $0 + $1.skippedBreaks }
        let totalWorkTime = records.reduce(0) { $0 + $1.workTimeSeconds }
        let totalBreakTime = records.reduce(0) { $0 + $1.breakTimeSeconds }
        
        return AggregateStatistics(
            totalCompletedWorkSessions: totalSessions,
            totalCompletedBreaks: totalBreaks,
            totalSkippedBreaks: totalSkipped,
            totalWorkTimeSeconds: totalWorkTime,
            totalBreakTimeSeconds: totalBreakTime
        )
    }
    
    public func recordWorkSessionCompleted(duration: TimeInterval) {
        mutateTodayRecord { record in
            record.completedWorkSessions += 1
            record.workTimeSeconds += duration
        }
    }
    
    public func recordBreakCompleted(duration: TimeInterval) {
        mutateTodayRecord { record in
            record.completedBreaks += 1
            record.breakTimeSeconds += duration
        }
    }
    
    public func recordBreakSkipped() {
        mutateTodayRecord { record in
            record.skippedBreaks += 1
        }
    }
    
    public func recordWorkTime(seconds: TimeInterval) {
        guard seconds > 0 else { return }
        mutateTodayRecord { record in
            record.workTimeSeconds += seconds
        }
    }
    
    public func recordBreakTime(seconds: TimeInterval) {
        guard seconds > 0 else { return }
        mutateTodayRecord { record in
            record.breakTimeSeconds += seconds
        }
    }
    
    public func clearAll() {
        records.removeAll()
        saveRecords()
    }
    
    // MARK: - Private Helpers
    
    private func mutateTodayRecord(_ mutation: (inout DailyRecord) -> Void) {
        let todayId = DateHelpers.dayIdentifier()
        if let index = records.firstIndex(where: { $0.dateIdentifier == todayId }) {
            var updated = records[index]
            mutation(&updated)
            records[index] = updated
        } else {
            var newRecord = DailyRecord(dateIdentifier: todayId)
            mutation(&newRecord)
            records.append(newRecord)
        }
        // Keep sorted by date descending (most recent first)
        records.sort { $0.dateIdentifier > $1.dateIdentifier }
        saveRecords()
    }
    
    private func loadRecords() {
        guard let data = userDefaults.data(forKey: storageKey) else { return }
        do {
            let decoded = try JSONDecoder().decode([DailyRecord].self, from: data)
            self.records = decoded.sorted { $0.dateIdentifier > $1.dateIdentifier }
        } catch {
            NSLog("[StatisticsManager] Failed to decode statistics: %@", error.localizedDescription)
        }
    }
    
    private func saveRecords() {
        do {
            let data = try JSONEncoder().encode(records)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            NSLog("[StatisticsManager] Failed to encode statistics: %@", error.localizedDescription)
        }
    }
}
