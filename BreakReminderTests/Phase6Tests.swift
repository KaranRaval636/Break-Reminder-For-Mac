import XCTest
@testable import BreakReminder

final class Phase6Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier ?? "com.breakreminder.BreakReminder")
    }
    
    // MARK: - Automation Hook Manager Tests
    
    func testAutomationHookEventDispatching() {
        let hookManager = AutomationHookManager.shared
        
        hookManager.handleEvent(.workSessionStarted)
        XCTAssertEqual(hookManager.lastDispatchedEvent, .workSessionStarted)
        XCTAssertNotNil(hookManager.lastDispatchedTimestamp)
        
        hookManager.handleEvent(.breakStarted(isLong: false))
        XCTAssertEqual(hookManager.lastDispatchedEvent, .breakStarted(isLong: false))
        XCTAssertEqual(hookManager.lastDispatchedEvent?.notificationName, "com.breakreminder.ShortBreakStarted")
        
        hookManager.handleEvent(.breakStarted(isLong: true))
        XCTAssertEqual(hookManager.lastDispatchedEvent?.notificationName, "com.breakreminder.LongBreakStarted")
        
        hookManager.handleEvent(.breakEnded)
        XCTAssertEqual(hookManager.lastDispatchedEvent, .breakEnded)
        XCTAssertEqual(hookManager.lastDispatchedEvent?.notificationName, "com.breakreminder.BreakEnded")
        
        hookManager.handleEvent(.breakSkipped)
        XCTAssertEqual(hookManager.lastDispatchedEvent, .breakSkipped)
        XCTAssertEqual(hookManager.lastDispatchedEvent?.notificationName, "com.breakreminder.BreakSkipped")
        
        hookManager.handleEvent(.smartPauseActivated(reason: "Meeting"))
        XCTAssertEqual(hookManager.lastDispatchedEvent, .smartPauseActivated(reason: "Meeting"))
        XCTAssertEqual(hookManager.lastDispatchedEvent?.notificationName, "com.breakreminder.SmartPauseActivated")
        
        hookManager.handleEvent(.smartPauseDeactivated)
        XCTAssertEqual(hookManager.lastDispatchedEvent, .smartPauseDeactivated)
        XCTAssertEqual(hookManager.lastDispatchedEvent?.notificationName, "com.breakreminder.SmartPauseDeactivated")
    }
    
    // MARK: - App Intents Tests
    
    @MainActor
    func testStartWorkSessionIntent() async throws {
        let intent = StartWorkSessionIntent()
        _ = try await intent.perform()
        
        XCTAssertEqual(TimerManager.shared.status, .working)
    }
    
    @MainActor
    func testStartBreakIntent() async throws {
        let intent = StartBreakIntent(isLongBreak: false)
        _ = try await intent.perform()
        
        XCTAssertEqual(TimerManager.shared.status, .onBreak)
        XCTAssertFalse(TimerManager.shared.isLongBreak)
    }
    
    @MainActor
    func testPauseBreakTimerIntent() async throws {
        TimerManager.shared.startWorkSession()
        XCTAssertEqual(TimerManager.shared.status, .working)
        
        let intent = PauseBreakTimerIntent()
        _ = try await intent.perform()
        XCTAssertEqual(TimerManager.shared.status, .paused)
        
        _ = try await intent.perform()
        XCTAssertEqual(TimerManager.shared.status, .working)
    }
    
    @MainActor
    func testGetScreenScoreIntent() async throws {
        let intent = GetScreenScoreIntent()
        _ = try await intent.perform()
        
        let today = StatisticsManager.shared.todayRecord
        let score = ScreenScore.calculate(for: today)
        XCTAssertGreaterThanOrEqual(score.value, 0)
        XCTAssertLessThanOrEqual(score.value, 100)
    }
}
