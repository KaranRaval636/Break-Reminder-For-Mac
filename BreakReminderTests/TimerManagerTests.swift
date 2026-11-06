import XCTest
@testable import BreakReminder

// MARK: - Mocks

final class MockSoundManager: SoundManaging {
    var playedWorkFinishedCount = 0
    var playedBreakFinishedCount = 0
    
    func playWorkFinishedSound() {
        playedWorkFinishedCount += 1
    }
    
    func playBreakFinishedSound() {
        playedBreakFinishedCount += 1
    }
}

final class MockNotificationManager: NotificationManaging {
    var requestedAuthCount = 0
    var sentWorkFinishedCount = 0
    var sentBreakFinishedCount = 0
    var cancelledCount = 0
    
    func requestAuthorizationIfNeeded() {
        requestedAuthCount += 1
    }
    
    func sendWorkFinishedNotification(isLongBreak: Bool) {
        sentWorkFinishedCount += 1
    }
    
    func sendBreakFinishedNotification() {
        sentBreakFinishedCount += 1
    }
    
    func cancelPendingNotifications() {
        cancelledCount += 1
    }
}

final class MockStatisticsManager: StatisticsManaging {
    var records: [DailyRecord] = []
    var aggregate: AggregateStatistics = AggregateStatistics()
    
    var recordedWorkSessions: [TimeInterval] = []
    var recordedBreaks: [TimeInterval] = []
    var recordedSkips = 0
    var recordedWorkTimes: [TimeInterval] = []
    var recordedBreakTimes: [TimeInterval] = []
    
    func recordWorkSessionCompleted(duration: TimeInterval) {
        recordedWorkSessions.append(duration)
    }
    
    func recordBreakCompleted(duration: TimeInterval) {
        recordedBreaks.append(duration)
    }
    
    func recordBreakSkipped() {
        recordedSkips += 1
    }
    
    func recordWorkTime(seconds: TimeInterval) {
        recordedWorkTimes.append(seconds)
    }
    
    func recordBreakTime(seconds: TimeInterval) {
        recordedBreakTimes.append(seconds)
    }
    
    func clearAll() {
        records.removeAll()
        recordedWorkSessions.removeAll()
        recordedBreaks.removeAll()
        recordedSkips = 0
    }
}

final class MockBreakWindowManager: BreakWindowManaging {
    var isShowingOverlay: Bool = false
    var activeWindowCount: Int = 0
    var showBreakCallCount = 0
    var hideBreakCallCount = 0
    var handleScreenParamsCount = 0
    
    func showBreakOverlay(timerManager: TimerManager) {
        isShowingOverlay = true
        showBreakCallCount += 1
    }
    
    func hideBreakOverlay() {
        isShowingOverlay = false
        hideBreakCallCount += 1
    }
    
    func handleScreenParametersChanged(timerManager: TimerManager?) {
        handleScreenParamsCount += 1
    }
}

// MARK: - TimerManagerTests

final class TimerManagerTests: XCTestCase {
    var userDefaults: UserDefaults!
    var settings: AppSettings!
    var soundManager: MockSoundManager!
    var notificationManager: MockNotificationManager!
    var statisticsManager: MockStatisticsManager!
    var breakWindowManager: MockBreakWindowManager!
    var sut: TimerManager!
    
    override func setUp() {
        super.setUp()
        let suiteName = "TimerManagerTests_\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)!
        settings = AppSettings(defaults: userDefaults)
        settings.workIntervalMinutes = 25
        settings.shortBreakMinutes = 5
        settings.longBreakMinutes = 15
        settings.longBreakFrequency = 4
        settings.snoozeDurationMinutes = 5
        settings.autoStartBreaks = true
        
        soundManager = MockSoundManager()
        notificationManager = MockNotificationManager()
        statisticsManager = MockStatisticsManager()
        breakWindowManager = MockBreakWindowManager()
        
        sut = TimerManager(
            settings: settings,
            soundManager: soundManager,
            notificationManager: notificationManager,
            statisticsManager: statisticsManager,
            breakWindowManager: breakWindowManager,
            defaults: userDefaults
        )
    }
    
    override func tearDown() {
        sut.resetTimer()
        userDefaults.removePersistentDomain(forName: userDefaults.description)
        super.tearDown()
    }
    
    func testStartWorkSession() {
        sut.startWorkSession()
        
        XCTAssertEqual(sut.status, .working)
        XCTAssertEqual(sut.totalDurationSeconds, 25 * 60)
        XCTAssertGreaterThan(sut.remainingSeconds, 0)
        XCTAssertNotNil(sut.targetEndDate)
        XCTAssertFalse(sut.isLongBreak)
        XCTAssertFalse(breakWindowManager.isShowingOverlay)
    }
    
    func testPauseAndResume() {
        sut.startWorkSession()
        let initialRemaining = sut.remainingSeconds
        
        sut.pauseTimer()
        XCTAssertEqual(sut.status, .paused)
        XCTAssertNil(sut.targetEndDate)
        
        // Wait a tiny bit and resume
        sut.resumeTimer()
        XCTAssertEqual(sut.status, .working)
        XCTAssertNotNil(sut.targetEndDate)
        XCTAssertEqual(sut.remainingSeconds, initialRemaining, accuracy: 1.0)
    }
    
    func testWorkTimerCompletionTriggersBreak() {
        sut.startWorkSession()
        
        // Simulate time passing to expiration
        let expirationDate = Date().addingTimeInterval(26 * 60)
        sut.tick(currentDate: expirationDate)
        
        XCTAssertEqual(sut.status, .onBreak)
        XCTAssertEqual(sut.completedWorkSessionsInCycle, 1)
        XCTAssertEqual(statisticsManager.recordedWorkSessions.count, 1)
        XCTAssertEqual(soundManager.playedWorkFinishedCount, 1)
        XCTAssertEqual(notificationManager.sentWorkFinishedCount, 1)
        XCTAssertTrue(breakWindowManager.isShowingOverlay)
    }
    
    func testBreakTimerCompletion() {
        sut.startBreak()
        XCTAssertEqual(sut.status, .onBreak)
        XCTAssertTrue(breakWindowManager.isShowingOverlay)
        
        // Simulate break expiration
        let breakEnd = Date().addingTimeInterval(6 * 60)
        sut.tick(currentDate: breakEnd)
        
        XCTAssertEqual(sut.status, .idle)
        XCTAssertFalse(breakWindowManager.isShowingOverlay)
        XCTAssertEqual(soundManager.playedBreakFinishedCount, 1)
        XCTAssertEqual(notificationManager.sentBreakFinishedCount, 1)
    }
    
    func testLongBreakScheduling() {
        // Complete 3 sessions
        for i in 1...3 {
            sut.startWorkSession()
            sut.tick(currentDate: Date().addingTimeInterval(26 * 60))
            XCTAssertEqual(sut.completedWorkSessionsInCycle, i)
            XCTAssertFalse(sut.isLongBreak)
            // Complete short break
            sut.tick(currentDate: Date().addingTimeInterval(6 * 60))
        }
        
        // 4th work session
        sut.startWorkSession()
        sut.tick(currentDate: Date().addingTimeInterval(26 * 60))
        
        // Should now be a long break!
        XCTAssertEqual(sut.completedWorkSessionsInCycle, 4)
        XCTAssertTrue(sut.isLongBreak)
        XCTAssertEqual(sut.totalDurationSeconds, 15 * 60)
        
        // Complete long break
        sut.tick(currentDate: Date().addingTimeInterval(16 * 60))
        // Cycle counter resets after completing long break
        XCTAssertEqual(sut.completedWorkSessionsInCycle, 0)
    }
    
    func testSkipBreak() {
        sut.startBreak()
        XCTAssertEqual(sut.status, .onBreak)
        XCTAssertTrue(breakWindowManager.isShowingOverlay)
        
        sut.skipBreak()
        
        XCTAssertEqual(sut.status, .idle)
        XCTAssertFalse(breakWindowManager.isShowingOverlay)
        XCTAssertEqual(statisticsManager.recordedSkips, 1)
    }
    
    func testSnoozeBreak() {
        settings.allowSnooze = true
        settings.snoozeDurationMinutes = 5
        
        sut.startBreak()
        XCTAssertEqual(sut.status, .onBreak)
        
        sut.snoozeBreak()
        
        XCTAssertEqual(sut.status, .working)
        XCTAssertEqual(sut.totalDurationSeconds, 5 * 60)
        XCTAssertFalse(breakWindowManager.isShowingOverlay)
    }
    
    func testStatePersistenceAndRecovery() {
        sut.startWorkSession()
        sut.saveState()
        
        // Create fresh manager restoring from the same defaults
        let restoredManager = TimerManager(
            settings: settings,
            soundManager: soundManager,
            notificationManager: notificationManager,
            statisticsManager: statisticsManager,
            breakWindowManager: breakWindowManager,
            defaults: userDefaults
        )
        
        XCTAssertEqual(restoredManager.status, .working)
        XCTAssertGreaterThan(restoredManager.remainingSeconds, 0)
        XCTAssertNotNil(restoredManager.targetEndDate)
    }
    
    func testStateRecoveryWhenWorkSessionExpiredWhileAppClosed() {
        sut.startWorkSession()
        sut.saveState()
        
        // Simulate recovering 2 hours later
        let futureDate = Date().addingTimeInterval(7200)
        
        let restoredManager = TimerManager(
            settings: settings,
            soundManager: soundManager,
            notificationManager: notificationManager,
            statisticsManager: statisticsManager,
            breakWindowManager: breakWindowManager,
            defaults: userDefaults
        )
        restoredManager.restorePersistedState(currentDate: futureDate)
        
        // It should gracefully transition to idle and record completed session
        XCTAssertEqual(restoredManager.status, .idle)
        XCTAssertEqual(restoredManager.completedWorkSessionsInCycle, 1)
    }
}
