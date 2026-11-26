import XCTest
@testable import BreakReminder

final class Phase2Tests: XCTestCase {
    var userDefaults: UserDefaults!
    var suiteName: String!
    
    override func setUp() {
        super.setUp()
        suiteName = "Phase2Tests_\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)!
    }
    
    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        userDefaults = nil
        super.tearDown()
    }
    
    func testAppearanceSettingsPersistence() {
        let settings = AppSettings(defaults: userDefaults)
        
        // Defaults
        XCTAssertEqual(settings.backgroundStyle, "aurora")
        XCTAssertEqual(settings.soundName, "Bell")
        XCTAssertEqual(settings.floatingCountdownEnabled, false)
        XCTAssertEqual(settings.floatingPosition, "topRight")
        XCTAssertTrue(settings.breathingGuideEnabled)
        
        // Mutate and verify
        settings.backgroundStyle = "dark"
        settings.soundName = "Chime"
        settings.floatingCountdownEnabled = true
        settings.floatingPosition = "bottomLeft"
        settings.breathingGuideEnabled = false
        
        let reloaded = AppSettings(defaults: userDefaults)
        XCTAssertEqual(reloaded.backgroundStyle, "dark")
        XCTAssertEqual(reloaded.soundName, "Chime")
        XCTAssertEqual(reloaded.floatingCountdownEnabled, true)
        XCTAssertEqual(reloaded.floatingPosition, "bottomLeft")
        XCTAssertFalse(reloaded.breathingGuideEnabled)
    }
    
    func testWellnessSoundPresets() {
        let allPresets = WellnessSoundPreset.allCases
        XCTAssertEqual(allPresets.count, 6)
        
        XCTAssertEqual(WellnessSoundPreset.bell.systemSoundName, "Glass")
        XCTAssertEqual(WellnessSoundPreset.chime.systemSoundName, "Hero")
        XCTAssertEqual(WellnessSoundPreset.ping.systemSoundName, "Ping")
        XCTAssertEqual(WellnessSoundPreset.tink.systemSoundName, "Tink")
        XCTAssertEqual(WellnessSoundPreset.submarine.systemSoundName, "Submarine")
        XCTAssertNil(WellnessSoundPreset.silent.systemSoundName)
    }
    
    func testCustomTipsConfiguration() {
        let settings = AppSettings(defaults: userDefaults)
        XCTAssertFalse(settings.customTips.isEmpty)
        
        let newTips = ["Drink water", "Stand and stretch"]
        settings.customTips = newTips
        
        let reloaded = AppSettings(defaults: userDefaults)
        XCTAssertEqual(reloaded.customTips, newTips)
    }
    
    func testFloatingCountdownVisibilityLogic() {
        let settings = AppSettings(defaults: userDefaults)
        let timer = TimerManager(settings: settings, defaults: userDefaults)
        let hudManager = FloatingCountdownManager(settings: settings, timerManager: timer)
        
        // Disabled by default
        hudManager.updateVisibility()
        XCTAssertFalse(hudManager.isVisible)
        
        // Enabled, but timer is idle -> should remain invisible
        settings.floatingCountdownEnabled = true
        hudManager.updateVisibility()
        XCTAssertFalse(hudManager.isVisible)
        
        // Enabled, timer is working -> should be visible
        timer.startWorkSession()
        hudManager.updateVisibility()
        XCTAssertTrue(hudManager.isVisible)
        
        // Timer transitions to break -> should hide HUD (overlay takes precedence)
        timer.startBreak()
        hudManager.updateVisibility()
        XCTAssertFalse(hudManager.isVisible)
        
        // Clean up
        hudManager.hideWindow()
    }
}
