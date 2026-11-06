import XCTest
import AppKit
@testable import BreakReminder

final class MockScreenProvider: ScreenProvider {
    var screens: [ScreenDescriptor] = []
    
    func getScreens() -> [ScreenDescriptor] {
        return screens
    }
}

final class MockOverlayWindowFactory: OverlayWindowFactory {
    var createdWindows: [NSWindow] = []
    
    func createWindow(for screen: ScreenDescriptor, content: NSView) -> NSWindow {
        let window = BreakOverlayWindow(
            contentRect: screen.frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.level = .modalPanel
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        window.contentView = content
        createdWindows.append(window)
        return window
    }
}

final class BreakWindowManagerTests: XCTestCase {
    var mockScreenProvider: MockScreenProvider!
    var mockWindowFactory: MockOverlayWindowFactory!
    var settings: AppSettings!
    var userDefaults: UserDefaults!
    var sut: BreakWindowManager!
    var timerManager: TimerManager!
    
    override func setUp() {
        super.setUp()
        let suiteName = "BreakWindowManagerTests_\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)!
        settings = AppSettings(defaults: userDefaults)
        settings.allDisplays = true
        
        mockScreenProvider = MockScreenProvider()
        mockWindowFactory = MockOverlayWindowFactory()
        
        sut = BreakWindowManager(
            screenProvider: mockScreenProvider,
            windowFactory: mockWindowFactory,
            settings: settings
        )
        
        timerManager = TimerManager(
            settings: settings,
            soundManager: MockSoundManager(),
            notificationManager: MockNotificationManager(),
            statisticsManager: MockStatisticsManager(),
            breakWindowManager: sut,
            defaults: userDefaults
        )
    }
    
    override func tearDown() {
        sut.hideBreakOverlay()
        userDefaults.removePersistentDomain(forName: userDefaults.description)
        super.tearDown()
    }
    
    func testSingleMonitorOverlayCreation() {
        let screen1 = ScreenDescriptor(
            id: "screen_1",
            frame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            visibleFrame: CGRect(x: 0, y: 0, width: 1920, height: 1055)
        )
        mockScreenProvider.screens = [screen1]
        
        sut.showBreakOverlay(timerManager: timerManager)
        
        XCTAssertTrue(sut.isShowingOverlay)
        XCTAssertEqual(sut.activeWindowCount, 1)
        XCTAssertEqual(mockWindowFactory.createdWindows.count, 1)
        
        let created = mockWindowFactory.createdWindows.first
        XCTAssertNotNil(created)
        XCTAssertEqual(created?.level, .modalPanel)
        XCTAssertTrue(created?.collectionBehavior.contains(.canJoinAllSpaces) ?? false)
        XCTAssertTrue(created?.collectionBehavior.contains(.fullScreenAuxiliary) ?? false)
        XCTAssertTrue(created?.canBecomeKey ?? false)
    }
    
    func testMultiMonitorOverlayCreation() {
        let screen1 = ScreenDescriptor(
            id: "screen_main",
            frame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            visibleFrame: CGRect(x: 0, y: 0, width: 1920, height: 1055)
        )
        let screen2 = ScreenDescriptor(
            id: "screen_external",
            frame: CGRect(x: 1920, y: 0, width: 2560, height: 1440),
            visibleFrame: CGRect(x: 1920, y: 0, width: 2560, height: 1440)
        )
        mockScreenProvider.screens = [screen1, screen2]
        
        sut.showBreakOverlay(timerManager: timerManager)
        
        XCTAssertTrue(sut.isShowingOverlay)
        XCTAssertEqual(sut.activeWindowCount, 2)
        XCTAssertEqual(mockWindowFactory.createdWindows.count, 2)
    }
    
    func testAllDisplaysDisabledOnlyCoversPrimaryScreen() {
        settings.allDisplays = false
        
        let screen1 = ScreenDescriptor(
            id: "screen_main",
            frame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            visibleFrame: CGRect(x: 0, y: 0, width: 1920, height: 1055)
        )
        let screen2 = ScreenDescriptor(
            id: "screen_external",
            frame: CGRect(x: 1920, y: 0, width: 2560, height: 1440),
            visibleFrame: CGRect(x: 1920, y: 0, width: 2560, height: 1440)
        )
        mockScreenProvider.screens = [screen1, screen2]
        
        sut.showBreakOverlay(timerManager: timerManager)
        
        XCTAssertTrue(sut.isShowingOverlay)
        XCTAssertEqual(sut.activeWindowCount, 1)
    }
    
    func testDisplayAdditionWhileBreakIsActive() {
        let screen1 = ScreenDescriptor(
            id: "screen_1",
            frame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            visibleFrame: CGRect(x: 0, y: 0, width: 1920, height: 1055)
        )
        mockScreenProvider.screens = [screen1]
        
        sut.showBreakOverlay(timerManager: timerManager)
        XCTAssertEqual(sut.activeWindowCount, 1)
        
        // Plug in 2nd monitor
        let screen2 = ScreenDescriptor(
            id: "screen_2",
            frame: CGRect(x: 1920, y: 0, width: 1920, height: 1080),
            visibleFrame: CGRect(x: 1920, y: 0, width: 1920, height: 1080)
        )
        mockScreenProvider.screens = [screen1, screen2]
        sut.handleScreenParametersChanged(timerManager: timerManager)
        
        XCTAssertEqual(sut.activeWindowCount, 2)
    }
    
    func testDisplayRemovalWhileBreakIsActive() {
        let screen1 = ScreenDescriptor(
            id: "screen_1",
            frame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            visibleFrame: CGRect(x: 0, y: 0, width: 1920, height: 1055)
        )
        let screen2 = ScreenDescriptor(
            id: "screen_2",
            frame: CGRect(x: 1920, y: 0, width: 1920, height: 1080),
            visibleFrame: CGRect(x: 1920, y: 0, width: 1920, height: 1080)
        )
        mockScreenProvider.screens = [screen1, screen2]
        
        sut.showBreakOverlay(timerManager: timerManager)
        XCTAssertEqual(sut.activeWindowCount, 2)
        
        // Unplug 2nd monitor
        mockScreenProvider.screens = [screen1]
        sut.handleScreenParametersChanged(timerManager: timerManager)
        
        XCTAssertEqual(sut.activeWindowCount, 1)
    }
    
    func testHideBreakOverlayClosesAllWindows() {
        let screen1 = ScreenDescriptor(
            id: "screen_1",
            frame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            visibleFrame: CGRect(x: 0, y: 0, width: 1920, height: 1055)
        )
        mockScreenProvider.screens = [screen1]
        
        sut.showBreakOverlay(timerManager: timerManager)
        XCTAssertTrue(sut.isShowingOverlay)
        XCTAssertEqual(sut.activeWindowCount, 1)
        
        sut.hideBreakOverlay()
        XCTAssertFalse(sut.isShowingOverlay)
        XCTAssertEqual(sut.activeWindowCount, 0)
    }
}
