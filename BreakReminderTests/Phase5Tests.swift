import XCTest
@testable import BreakReminder

final class Phase5Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier ?? "com.breakreminder.BreakReminder")
    }
    
    // MARK: - DailyRecord and Metrics Tests
    
    func testDailyRecordMetrics() {
        let record = DailyRecord(
            dateIdentifier: "2026-11-09",
            completedWorkSessions: 4,
            completedBreaks: 3,
            skippedBreaks: 1,
            workTimeSeconds: 7200, // 2 hours
            breakTimeSeconds: 900,  // 15 mins
            naturalBreaks: 1,
            longestWorkSessionSeconds: 2400
        )
        
        // Average work session: 7200 / 4 = 1800s (30m)
        XCTAssertEqual(record.averageWorkSessionSeconds, 1800)
        
        // Average break duration: 900 / (3 + 1) = 225s (3m 45s)
        XCTAssertEqual(record.averageBreakDurationSeconds, 225)
        
        // Compliance rate: 3 completed / (3 + 1) = 0.75
        XCTAssertEqual(record.complianceRate, 0.75)
        
        XCTAssertEqual(record.longestWorkSessionSeconds, 2400)
    }
    
    func testAggregateStatisticsCalculation() {
        let statsManager = StatisticsManager(userDefaults: UserDefaults.standard)
        statsManager.clearAll()
        
        statsManager.recordWorkSessionCompleted(duration: 1800)
        statsManager.recordWorkSessionCompleted(duration: 3600)
        statsManager.recordBreakCompleted(duration: 300)
        statsManager.recordBreakSkipped()
        statsManager.recordNaturalBreak()
        statsManager.recordBreakTime(seconds: 300)
        
        let agg = statsManager.aggregate
        XCTAssertEqual(agg.totalCompletedWorkSessions, 2)
        XCTAssertEqual(agg.totalWorkTimeSeconds, 5400)
        XCTAssertEqual(agg.totalCompletedBreaks, 1)
        XCTAssertEqual(agg.totalSkippedBreaks, 1)
        XCTAssertEqual(agg.totalNaturalBreaks, 1)
        XCTAssertEqual(agg.totalBreakTimeSeconds, 600)
        XCTAssertEqual(agg.longestWorkSessionSeconds, 3600)
        XCTAssertEqual(agg.averageWorkSessionSeconds, 2700)
        XCTAssertEqual(agg.averageBreakDurationSeconds, 300) // 600 / (1 completed + 1 natural)
    }
    
    func testRecentDaysFilling() {
        let statsManager = StatisticsManager(userDefaults: UserDefaults.standard)
        statsManager.clearAll()
        
        let recent7 = statsManager.recentDays(count: 7)
        XCTAssertEqual(recent7.count, 7)
        
        // Dates should be sorted chronologically
        for i in 0..<6 {
            XCTAssertLessThan(recent7[i].dateIdentifier, recent7[i+1].dateIdentifier)
        }
    }
    
    // MARK: - ScreenScore Algorithm Tests
    
    func testScreenScoreBaselineWhenNoWorkDone() {
        let freshRecord = DailyRecord(dateIdentifier: "2026-11-09")
        let score = ScreenScore.calculate(for: freshRecord)
        
        XCTAssertEqual(score.value, 100)
        XCTAssertEqual(score.rating, "Optimal")
    }
    
    func testScreenScoreTransparentCalculation() {
        // Record with 4 breaks taken, 1 skip, 2 natural breaks, 2 hours work and 20 mins rest
        let record = DailyRecord(
            dateIdentifier: "2026-11-09",
            completedWorkSessions: 4,
            completedBreaks: 4,
            skippedBreaks: 1,
            workTimeSeconds: 7200, // 2 hours
            breakTimeSeconds: 1200, // 20 mins (10 min rest per hour -> 20 pts)
            naturalBreaks: 2
        )
        
        let score = ScreenScore.calculate(for: record)
        let b = score.breakdown
        
        // Base: 35
        XCTAssertEqual(b.basePoints, 35)
        
        // Break adherence: 4 / 5 * 35 = 28
        XCTAssertEqual(b.breakAdherencePoints, 28)
        
        // Natural break bonus: 2 * 5 = 10
        XCTAssertEqual(b.naturalBreakBonus, 10)
        
        // Work-to-rest ratio: 20 min / 2 hr = 10 min/hr -> 20 pts
        XCTAssertEqual(b.workRestRatioPoints, 20)
        
        // Skip penalty: 1 * 6 = 6
        XCTAssertEqual(b.skipPenalty, 6)
        
        // Total score: 35 + 28 + 10 + 20 - 6 = 87
        XCTAssertEqual(b.totalScore, 87)
        XCTAssertEqual(score.value, 87)
        XCTAssertEqual(score.rating, "Optimal")
    }
    
    func testScreenScorePenaltyForExcessiveSkips() {
        let record = DailyRecord(
            dateIdentifier: "2026-11-09",
            completedWorkSessions: 5,
            completedBreaks: 0,
            skippedBreaks: 6, // 6 skips = -36 pts penalty
            workTimeSeconds: 14400,
            breakTimeSeconds: 0,
            naturalBreaks: 0
        )
        
        let score = ScreenScore.calculate(for: record)
        // Base: 35, Adherence: 0, Natural: 0, Ratio: 0, Penalty: 36
        // 35 - 36 = -1, clamped to min 10
        XCTAssertEqual(score.value, 10)
        XCTAssertEqual(score.rating, "Needs Attention")
    }
}
