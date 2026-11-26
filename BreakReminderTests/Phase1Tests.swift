import XCTest
@testable import BreakReminder

final class Phase1Tests: XCTestCase {
    var userDefaults: UserDefaults!
    var suiteName: String!
    
    override func setUp() {
        super.setUp()
        suiteName = "Phase1Tests_\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)!
    }
    
    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        userDefaults = nil
        super.tearDown()
    }
    
    func testBreakProfileDefaultsAndApplication() {
        let settings = AppSettings(defaults: userDefaults)
        
        // Default profile is balanced
        XCTAssertEqual(settings.breakProfile, .balanced)
        XCTAssertEqual(settings.workIntervalMinutes, 50)
        XCTAssertEqual(settings.shortBreakMinutes, 5)
        XCTAssertEqual(settings.longBreakMinutes, 15)
        XCTAssertEqual(settings.longBreakFrequency, 4)
        
        // Switch to Deep Work
        settings.applyProfile(.deepWork)
        XCTAssertEqual(settings.breakProfile, .deepWork)
        XCTAssertEqual(settings.workIntervalMinutes, 90)
        XCTAssertEqual(settings.shortBreakMinutes, 15)
        XCTAssertEqual(settings.longBreakMinutes, 30)
        XCTAssertEqual(settings.longBreakFrequency, 2)
        
        // Switch to Eye Care (20-20-20 rule)
        settings.applyProfile(.eyeCare)
        XCTAssertEqual(settings.breakProfile, .eyeCare)
        XCTAssertEqual(settings.workIntervalMinutes, 20)
        XCTAssertEqual(settings.shortBreakMinutes, 1)
        XCTAssertEqual(settings.longBreakMinutes, 10)
        XCTAssertEqual(settings.longBreakFrequency, 6)
    }
    
    func testScreenScoreCalculation() {
        // Test brand new day with 0 work time -> 100 base score
        let emptyDay = DailyRecord(dateIdentifier: "2026-11-09")
        let initialScore = ScreenScore.calculate(for: emptyDay)
        XCTAssertEqual(initialScore.value, 100)
        XCTAssertEqual(initialScore.rating, "Optimal")
        
        // Test healthy day with completed breaks and natural breaks
        let healthyDay = DailyRecord(
            dateIdentifier: "2026-11-09",
            completedWorkSessions: 4,
            completedBreaks: 4,
            skippedBreaks: 0,
            workTimeSeconds: 4 * 50 * 60,
            breakTimeSeconds: 4 * 5 * 60,
            naturalBreaks: 2
        )
        let healthyScore = ScreenScore.calculate(for: healthyDay)
        XCTAssertGreaterThanOrEqual(healthyScore.value, 80)
        
        // Test day with multiple skips
        let skippedDay = DailyRecord(
            dateIdentifier: "2026-11-09",
            completedWorkSessions: 4,
            completedBreaks: 1,
            skippedBreaks: 4,
            workTimeSeconds: 4 * 50 * 60,
            breakTimeSeconds: 1 * 5 * 60,
            naturalBreaks: 0
        )
        let skippedScore = ScreenScore.calculate(for: skippedDay)
        XCTAssertLessThan(skippedScore.value, healthyScore.value)
    }
    
    func testPreBreakNotificationTrigger() {
        let settings = AppSettings(defaults: userDefaults)
        settings.workIntervalMinutes = 10
        settings.preBreakNotificationEnabled = true
        settings.preBreakNotificationLeadMinutes = 1
        
        final class MockNotificationManager: NotificationManaging {
            var preBreakSent = false
            func requestAuthorizationIfNeeded() {}
            func sendWorkFinishedNotification(isLongBreak: Bool) {}
            func sendBreakFinishedNotification() {}
            func sendPreBreakNotification(minutesRemaining: Int) {
                preBreakSent = true
            }
            func cancelPendingNotifications() {}
        }
        
        let mockNotif = MockNotificationManager()
        let timer = TimerManager(
            settings: settings,
            notificationManager: mockNotif,
            defaults: userDefaults
        )
        
        timer.startWorkSession()
        XCTAssertFalse(mockNotif.preBreakSent)
        
        // Simulate tick at 30 seconds remaining (within the 1 minute lead)
        guard let target = timer.targetEndDate else {
            XCTFail("Target end date should be set")
            return
        }
        let dateWithinLead = target.addingTimeInterval(-30)
        timer.tick(currentDate: dateWithinLead)
        
        XCTAssertTrue(mockNotif.preBreakSent, "Pre-break notification should have fired within lead window")
    }
    
    func testSnoozeLimitEnforcement() {
        let settings = AppSettings(defaults: userDefaults)
        settings.allowSnooze = true
        settings.snoozeLimit = 2
        
        let timer = TimerManager(
            settings: settings,
            defaults: userDefaults
        )
        
        timer.startBreak(isLong: false)
        XCTAssertTrue(timer.canSnooze)
        XCTAssertEqual(timer.remainingSnoozes, 2)
        
        // Snooze 1
        timer.snoozeBreak()
        XCTAssertEqual(timer.currentSnoozeCount, 1)
        XCTAssertEqual(timer.remainingSnoozes, 1)
        XCTAssertTrue(timer.canSnooze)
        
        // Simulate entering break again
        timer.startBreak(isLong: false)
        // Snooze 2
        timer.snoozeBreak()
        XCTAssertEqual(timer.currentSnoozeCount, 2)
        XCTAssertEqual(timer.remainingSnoozes, 0)
        XCTAssertFalse(timer.canSnooze, "Snooze limit of 2 should now prevent further snoozes")
    }
    
    func testImmediateCustomDurationBreak() {
        let settings = AppSettings(defaults: userDefaults)
        let timer = TimerManager(settings: settings, defaults: userDefaults)
        
        timer.startImmediateBreak(durationMinutes: 12)
        XCTAssertEqual(timer.status, .onBreak)
        XCTAssertEqual(timer.totalDurationSeconds, 12 * 60)
        XCTAssertEqual(timer.remainingSeconds, 12 * 60)
    }
    
    func testSmartPauseApplicationAndResume() {
        let settings = AppSettings(defaults: userDefaults)
        let timer = TimerManager(settings: settings, defaults: userDefaults)
        
        timer.startWorkSession()
        XCTAssertEqual(timer.status, .working)
        XCTAssertFalse(timer.isSmartPaused)
        
        timer.applySmartPause(reason: "Active Zoom Meeting")
        XCTAssertTrue(timer.isSmartPaused)
        XCTAssertEqual(timer.smartPauseReason, "Active Zoom Meeting")
        XCTAssertEqual(timer.status, .paused)
        
        timer.resumeFromSmartPause()
        XCTAssertFalse(timer.isSmartPaused)
        XCTAssertNil(timer.smartPauseReason)
        XCTAssertEqual(timer.status, .working)
    }
}
