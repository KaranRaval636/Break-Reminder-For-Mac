import Foundation
import Combine

public protocol StatisticsManaging: AnyObject {
    var records: [DailyRecord] { get }
    var aggregate: AggregateStatistics { get }
    var todayRecord: DailyRecord { get }
    func recordWorkSessionCompleted(duration: TimeInterval)
    func recordBreakCompleted(duration: TimeInterval)
    func recordBreakSkipped()
    func recordNaturalBreak()
    func recordWorkTime(seconds: TimeInterval)
    func recordBreakTime(seconds: TimeInterval)
    func clearAll()
}

public extension StatisticsManaging {
    var todayRecord: DailyRecord {
        let todayId = DateHelpers.dayIdentifier()
        return records.first(where: { $0.dateIdentifier == todayId }) ?? DailyRecord(dateIdentifier: todayId)
    }
    
    func recordNaturalBreak() {}
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
    
    public var todayRecord: DailyRecord {
        let todayId = DateHelpers.dayIdentifier()
        return records.first(where: { $0.dateIdentifier == todayId }) ?? DailyRecord(dateIdentifier: todayId)
    }
    
    public var aggregate: AggregateStatistics {
        let totalSessions = records.reduce(0) { $0 + $1.completedWorkSessions }
        let totalBreaks = records.reduce(0) { $0 + $1.completedBreaks }
        let totalSkipped = records.reduce(0) { $0 + $1.skippedBreaks }
        let totalWorkTime = records.reduce(0) { $0 + $1.workTimeSeconds }
        let totalBreakTime = records.reduce(0) { $0 + $1.breakTimeSeconds }
        let totalNatural = records.reduce(0) { $0 + $1.naturalBreaks }
        let longestWork = records.map(\.longestWorkSessionSeconds).max() ?? 0
        
        let avgWork = totalSessions > 0 ? totalWorkTime / Double(totalSessions) : totalWorkTime
        let totalAllBreaks = totalBreaks + totalNatural
        let avgBreak = totalAllBreaks > 0 ? totalBreakTime / Double(totalAllBreaks) : 0
        
        return AggregateStatistics(
            totalCompletedWorkSessions: totalSessions,
            totalCompletedBreaks: totalBreaks,
            totalSkippedBreaks: totalSkipped,
            totalWorkTimeSeconds: totalWorkTime,
            totalBreakTimeSeconds: totalBreakTime,
            totalNaturalBreaks: totalNatural,
            longestWorkSessionSeconds: longestWork,
            averageWorkSessionSeconds: avgWork,
            averageBreakDurationSeconds: avgBreak
        )
    }
    
    /// Returns the last N days (chronological order) for charts, filling in any missing dates.
    public func recentDays(count: Int = 7) -> [DailyRecord] {
        var result: [DailyRecord] = []
        let calendar = Calendar.current
        let today = Date()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        for i in (0..<count).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let id = formatter.string(from: date)
            if let existing = records.first(where: { $0.dateIdentifier == id }) {
                result.append(existing)
            } else {
                result.append(DailyRecord(dateIdentifier: id))
            }
        }
        return result
    }
    
    public func recordWorkSessionCompleted(duration: TimeInterval) {
        mutateTodayRecord { record in
            record.completedWorkSessions += 1
            record.workTimeSeconds += duration
            if duration > record.longestWorkSessionSeconds {
                record.longestWorkSessionSeconds = duration
            }
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
    
    public func recordNaturalBreak() {
        mutateTodayRecord { record in
            record.naturalBreaks += 1
        }
    }
    
    public func recordWorkTime(seconds: TimeInterval) {
        guard seconds > 0 else { return }
        mutateTodayRecord { record in
            record.workTimeSeconds += seconds
            if seconds > record.longestWorkSessionSeconds {
                record.longestWorkSessionSeconds = seconds
            }
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
        records.sort { $0.dateIdentifier > $1.dateIdentifier }
        saveRecords()
    }
    
    private func loadRecords() {
        guard let data = userDefaults.data(forKey: storageKey) else { return }
        do {
            let decoded = try JSONDecoder().decode([DailyRecord].self, from: data)
            self.records = decoded
        } catch {
            NSLog("[StatisticsManager] Failed to decode daily records: %@", error.localizedDescription)
        }
    }
    
    private func saveRecords() {
        do {
            let data = try JSONEncoder().encode(records)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            NSLog("[StatisticsManager] Failed to encode daily records: %@", error.localizedDescription)
        }
    }
}
