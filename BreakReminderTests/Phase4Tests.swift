import XCTest
@testable import BreakReminder

final class Phase4Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier ?? "com.breakreminder.BreakReminder")
    }
    
    // MARK: - PlannedBreak Model Tests
    
    func testPlannedBreakActiveOnWeekday() {
        let breakItem = PlannedBreak(
            name: "Lunch Break",
            hour: 12,
            minute: 30,
            durationMinutes: 45,
            repeatDays: [2, 3, 4, 5, 6] // Mon-Fri
        )
        
        XCTAssertTrue(breakItem.isActiveOn(weekday: 2)) // Monday
        XCTAssertTrue(breakItem.isActiveOn(weekday: 6)) // Friday
        XCTAssertFalse(breakItem.isActiveOn(weekday: 1)) // Sunday
        XCTAssertFalse(breakItem.isActiveOn(weekday: 7)) // Saturday
        
        XCTAssertTrue(breakItem.formattedTime.contains("12:30"))
        XCTAssertTrue(breakItem.formattedTime.contains("PM"))
        XCTAssertEqual(breakItem.formattedDuration, "45m")
    }
    
    func testPlannedBreakPersistence() {
        let sample = [
            PlannedBreak(name: "Morning Stretch", hour: 10, minute: 15, durationMinutes: 10, repeatDays: [2, 4]),
            PlannedBreak(name: "Afternoon Walk", hour: 16, minute: 0, durationMinutes: 20, repeatDays: [1, 2, 3, 4, 5, 6, 7])
        ]
        
        AppSettings.shared.plannedBreaks = sample
        XCTAssertEqual(AppSettings.shared.plannedBreaks.count, 2)
        XCTAssertEqual(AppSettings.shared.plannedBreaks.first?.name, "Morning Stretch")
        XCTAssertEqual(AppSettings.shared.plannedBreaks.last?.durationMinutes, 20)
    }
    
    // MARK: - Office Hours Logic Tests
    
    func testOfficeHoursWithinAndOutsideHours() {
        let settings = AppSettings.shared
        settings.officeHoursEnabled = true
        settings.officeHoursOverride = false
        settings.officeHoursStartHour = 9
        settings.officeHoursStartMinute = 0
        settings.officeHoursEndHour = 17
        settings.officeHoursEndMinute = 30
        settings.officeHoursDays = [2, 3, 4, 5, 6] // Mon-Fri
        
        let officeManager = OfficeHoursManager(settings: settings, timerManager: TimerManager.shared)
        
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        // Monday 11:00 AM -> Inside
        var comp = DateComponents()
        comp.year = 2026
        comp.month = 11
        comp.day = 9 // Monday (weekday 2)
        comp.hour = 11
        comp.minute = 0
        if let mondayInside = calendar.date(from: comp) {
            XCTAssertTrue(officeManager.isWithinOfficeHours(date: mondayInside))
        }
        
        // Monday 8:30 AM -> Before start -> Outside
        comp.hour = 8
        comp.minute = 30
        if let mondayBefore = calendar.date(from: comp) {
            XCTAssertFalse(officeManager.isWithinOfficeHours(date: mondayBefore))
        }
        
        // Monday 18:00 (6:00 PM) -> After end -> Outside
        comp.hour = 18
        comp.minute = 0
        if let mondayAfter = calendar.date(from: comp) {
            XCTAssertFalse(officeManager.isWithinOfficeHours(date: mondayAfter))
        }
        
        // Sunday 11:00 AM -> Weekend (weekday 1) -> Outside
        comp.day = 8 // Sunday (weekday 1)
        comp.hour = 11
        if let sunday = calendar.date(from: comp) {
            XCTAssertFalse(officeManager.isWithinOfficeHours(date: sunday))
        }
        
        // When Override is true -> Always within
        settings.officeHoursOverride = true
        if let sunday = calendar.date(from: comp) {
            XCTAssertTrue(officeManager.isWithinOfficeHours(date: sunday))
        }
        
        // When Office Hours is disabled -> Always within
        settings.officeHoursOverride = false
        settings.officeHoursEnabled = false
        if let sunday = calendar.date(from: comp) {
            XCTAssertTrue(officeManager.isWithinOfficeHours(date: sunday))
        }
    }
    
    // MARK: - Wellness Reminders Suppression Tests
    
    func testWellnessSuppressionWhenBreakActive() {
        let timer = TimerManager.shared
        timer.startBreak(isLong: false)
        
        let wellnessManager = WellnessReminderManager.shared
        XCTAssertTrue(wellnessManager.shouldSuppressReminders(), "Wellness reminders should be suppressed during break")
        
        timer.startWorkSession()
        XCTAssertFalse(wellnessManager.shouldSuppressReminders(), "Wellness reminders should not be suppressed during active work without smart pause")
    }
    
    // MARK: - Natural Break Tests
    
    func testNaturalBreakEvaluation() {
        let stats = StatisticsManager.shared
        let initialNaturalBreaks = stats.todayRecord.naturalBreaks
        
        let settings = AppSettings.shared
        settings.naturalBreakEnabled = true
        settings.naturalBreakThresholdSeconds = 120 // 2 minutes
        
        let timer = TimerManager.shared
        timer.startWorkSession()
        
        let naturalManager = NaturalBreakManager.shared
        
        // User was away for 300 seconds (> 120s threshold)
        naturalManager.evaluateUserReturn(idleDuration: 300)
        
        // Natural break should have been recorded
        XCTAssertEqual(stats.todayRecord.naturalBreaks, initialNaturalBreaks + 1)
        // Timer should have been reset to work interval
        XCTAssertEqual(timer.status, .working)
        XCTAssertEqual(timer.remainingSeconds, Double(settings.workIntervalMinutes * 60))
    }
}
