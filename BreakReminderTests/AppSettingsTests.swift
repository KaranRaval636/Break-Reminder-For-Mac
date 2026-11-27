import XCTest
@testable import BreakReminder

final class AppSettingsTests: XCTestCase {
    var userDefaults: UserDefaults!
    var sut: AppSettings!
    
    override func setUp() {
        super.setUp()
        let suiteName = "AppSettingsTests_\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)!
        sut = AppSettings(defaults: userDefaults)
    }
    
    override func tearDown() {
        userDefaults.removePersistentDomain(forName: userDefaults.description)
        super.tearDown()
    }
    
    func testClampingWorkInterval() {
        sut.workIntervalMinutes = -10
        XCTAssertEqual(sut.workIntervalMinutes, AppSettings.minWorkMinutes)
        
        sut.workIntervalMinutes = 9999
        XCTAssertEqual(sut.workIntervalMinutes, AppSettings.maxWorkMinutes)
    }
    
    func testClampingBreakDurations() {
        sut.shortBreakMinutes = 0
        XCTAssertEqual(sut.shortBreakMinutes, AppSettings.minBreakMinutes)
        
        sut.longBreakMinutes = 200
        XCTAssertEqual(sut.longBreakMinutes, AppSettings.maxBreakMinutes)
    }
    
    func testRestoreDefaults() {
        sut.workIntervalMinutes = 120
        sut.shortBreakMinutes = 20
        sut.longBreakMinutes = 45
        sut.longBreakFrequency = 2
        sut.snoozeDurationMinutes = 10
        sut.allDisplays = false
        sut.soundEnabled = false
        sut.notificationsEnabled = false
        sut.allowScreenAccessDuringBreak = false
        
        sut.restoreDefaults()
        
        XCTAssertEqual(sut.workIntervalMinutes, AppSettings.defaultWorkIntervalMinutes)
        XCTAssertEqual(sut.shortBreakMinutes, AppSettings.defaultShortBreakMinutes)
        XCTAssertEqual(sut.longBreakMinutes, AppSettings.defaultLongBreakMinutes)
        XCTAssertEqual(sut.longBreakFrequency, AppSettings.defaultLongBreakFrequency)
        XCTAssertEqual(sut.snoozeDurationMinutes, AppSettings.defaultSnoozeDurationMinutes)
        XCTAssertEqual(sut.allDisplays, AppSettings.defaultAllDisplays)
        XCTAssertEqual(sut.soundEnabled, AppSettings.defaultSoundEnabled)
        XCTAssertEqual(sut.notificationsEnabled, AppSettings.defaultNotificationsEnabled)
        XCTAssertEqual(sut.allowScreenAccessDuringBreak, AppSettings.defaultAllowScreenAccessDuringBreak)
    }
    
    func testAllowScreenAccessDuringBreakSetting() {
        XCTAssertTrue(sut.allowScreenAccessDuringBreak)
        sut.allowScreenAccessDuringBreak = false
        XCTAssertFalse(sut.allowScreenAccessDuringBreak)
        
        let restored = AppSettings(defaults: userDefaults)
        XCTAssertFalse(restored.allowScreenAccessDuringBreak)
    }
}
