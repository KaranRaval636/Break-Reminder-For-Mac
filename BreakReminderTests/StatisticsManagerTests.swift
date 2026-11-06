import XCTest
@testable import BreakReminder

final class StatisticsManagerTests: XCTestCase {
    var userDefaults: UserDefaults!
    var sut: StatisticsManager!
    
    override func setUp() {
        super.setUp()
        let suiteName = "StatisticsManagerTests_\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)!
        sut = StatisticsManager(userDefaults: userDefaults)
    }
    
    override func tearDown() {
        sut.clearAll()
        userDefaults.removePersistentDomain(forName: userDefaults.description)
        super.tearDown()
    }
    
    func testRecordingWorkAndBreaks() {
        sut.recordWorkSessionCompleted(duration: 1500)
        sut.recordBreakCompleted(duration: 300)
        sut.recordBreakSkipped()
        
        let aggregate = sut.aggregate
        XCTAssertEqual(aggregate.totalCompletedWorkSessions, 1)
        XCTAssertEqual(aggregate.totalCompletedBreaks, 1)
        XCTAssertEqual(aggregate.totalSkippedBreaks, 1)
        XCTAssertEqual(aggregate.totalWorkTimeSeconds, 1500)
        XCTAssertEqual(aggregate.totalBreakTimeSeconds, 300)
        
        XCTAssertEqual(sut.records.count, 1)
        let today = sut.records.first
        XCTAssertEqual(today?.completedWorkSessions, 1)
        XCTAssertEqual(today?.completedBreaks, 1)
        XCTAssertEqual(today?.skippedBreaks, 1)
    }
    
    func testClearAllStatistics() {
        sut.recordWorkSessionCompleted(duration: 1800)
        XCTAssertFalse(sut.records.isEmpty)
        
        sut.clearAll()
        XCTAssertTrue(sut.records.isEmpty)
        XCTAssertEqual(sut.aggregate.totalCompletedWorkSessions, 0)
    }
}
