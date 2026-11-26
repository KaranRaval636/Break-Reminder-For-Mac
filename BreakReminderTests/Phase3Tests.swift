import XCTest
@testable import BreakReminder

final class Phase3Tests: XCTestCase {
    var userDefaults: UserDefaults!
    var suiteName: String!
    
    override func setUp() {
        super.setUp()
        suiteName = "Phase3Tests_\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)!
    }
    
    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        userDefaults = nil
        super.tearDown()
    }
    
    // MARK: - 1. Idle Detector Tests
    
    func testIdleDetector() {
        let settings = AppSettings(defaults: userDefaults)
        settings.smartPauseEnabled = true
        settings.smartPauseIdleEnabled = true
        settings.smartPauseIdleThresholdSeconds = 120
        
        final class MockIdleProvider: IdleTimeProvider {
            var idle: TimeInterval = 0
            func systemIdleSeconds() -> TimeInterval { idle }
        }
        
        let provider = MockIdleProvider()
        let detector = IdleDetector(settings: settings, idleProvider: provider)
        
        // 30 seconds idle -> below 120 threshold -> nil
        provider.idle = 30
        XCTAssertNil(detector.checkPauseCondition())
        
        // 150 seconds idle -> above threshold -> triggers pause
        provider.idle = 150
        let reason = detector.checkPauseCondition()
        XCTAssertNotNil(reason)
        XCTAssertEqual(reason?.type, .idle)
        
        // When detector is disabled in settings -> nil
        settings.smartPauseIdleEnabled = false
        XCTAssertNil(detector.checkPauseCondition())
    }
    
    // MARK: - 2. Fullscreen Detector Tests
    
    func testFullscreenDetector() {
        let settings = AppSettings(defaults: userDefaults)
        settings.smartPauseEnabled = true
        settings.smartPauseFullscreenEnabled = true
        
        final class MockFullscreenInspector: FullscreenInspector {
            var fullscreen = false
            var app = "Keynote"
            func isFrontmostAppFullscreen() -> (isFullscreen: Bool, appName: String) {
                (fullscreen, app)
            }
        }
        
        let inspector = MockFullscreenInspector()
        let detector = FullscreenDetector(settings: settings, inspector: inspector)
        
        inspector.fullscreen = false
        XCTAssertNil(detector.checkPauseCondition())
        
        inspector.fullscreen = true
        let reason = detector.checkPauseCondition()
        XCTAssertNotNil(reason)
        XCTAssertEqual(reason?.type, .fullscreen)
        XCTAssertTrue(reason?.detail.contains("Keynote") == true)
    }
    
    // MARK: - 3. Meeting Detector Tests
    
    func testMeetingDetector() {
        let settings = AppSettings(defaults: userDefaults)
        settings.smartPauseEnabled = true
        settings.smartPauseMeetingEnabled = true
        
        final class MockMeetingInspector: MeetingInspector {
            var inMeeting = false
            var app = "Zoom"
            func detectActiveMeeting() -> (isMeeting: Bool, appName: String) {
                (inMeeting, app)
            }
        }
        
        let inspector = MockMeetingInspector()
        let detector = MeetingDetector(settings: settings, inspector: inspector)
        
        inspector.inMeeting = false
        XCTAssertNil(detector.checkPauseCondition())
        
        inspector.inMeeting = true
        let reason = detector.checkPauseCondition()
        XCTAssertNotNil(reason)
        XCTAssertEqual(reason?.type, .meeting)
        XCTAssertTrue(reason?.detail.contains("Zoom") == true)
    }
    
    // MARK: - 4. Screen Recording Detector Tests
    
    func testRecordingDetector() {
        let settings = AppSettings(defaults: userDefaults)
        settings.smartPauseEnabled = true
        settings.smartPauseRecordingEnabled = true
        
        final class MockRecordingInspector: RecordingInspector {
            var recording = false
            var app = "OBS Studio"
            func isScreenRecordingActive() -> (isRecording: Bool, appName: String) {
                (recording, app)
            }
        }
        
        let inspector = MockRecordingInspector()
        let detector = ScreenRecordingDetector(settings: settings, inspector: inspector)
        
        inspector.recording = false
        XCTAssertNil(detector.checkPauseCondition())
        
        inspector.recording = true
        let reason = detector.checkPauseCondition()
        XCTAssertNotNil(reason)
        XCTAssertEqual(reason?.type, .screenRecording)
    }
    
    // MARK: - 5. Video Playback Detector Tests
    
    func testVideoDetector() {
        let settings = AppSettings(defaults: userDefaults)
        settings.smartPauseEnabled = true
        settings.smartPauseVideoEnabled = true
        
        final class MockVideoInspector: VideoPlaybackInspector {
            var playing = false
            var app = "VLC Media Player"
            func isVideoPlaybackActive() -> (isPlaying: Bool, appName: String) {
                (playing, app)
            }
        }
        
        let inspector = MockVideoInspector()
        let detector = VideoPlaybackDetector(settings: settings, inspector: inspector)
        
        inspector.playing = false
        XCTAssertNil(detector.checkPauseCondition())
        
        inspector.playing = true
        let reason = detector.checkPauseCondition()
        XCTAssertNotNil(reason)
        XCTAssertEqual(reason?.type, .videoPlayback)
    }
    
    // MARK: - 6. Focus App Exclusions Tests
    
    func testFocusAppExclusionList() {
        let settings = AppSettings(defaults: userDefaults)
        settings.smartPauseEnabled = true
        settings.smartPauseFocusAppsEnabled = true
        settings.excludedApps = [
            ExcludedApp(bundleIdentifier: "com.apple.dt.Xcode", name: "Xcode")
        ]
        
        let timer = TimerManager(settings: settings, defaults: userDefaults)
        let manager = SmartPauseManager(
            settings: settings,
            timerManager: timer
        )
        
        // Test adding app
        manager.addExcludedApp(bundleIdentifier: "com.figma.Desktop", name: "Figma")
        XCTAssertTrue(settings.excludedApps.contains { $0.bundleIdentifier == "com.figma.Desktop" })
        
        // Test removing app
        manager.removeExcludedApp(id: "com.apple.dt.Xcode")
        XCTAssertFalse(settings.excludedApps.contains { $0.bundleIdentifier == "com.apple.dt.Xcode" })
    }
}
