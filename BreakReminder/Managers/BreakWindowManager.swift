import AppKit
import SwiftUI

public struct ScreenDescriptor: Equatable, Hashable {
    public let id: String
    public let frame: CGRect
    public let visibleFrame: CGRect
    
    public init(id: String, frame: CGRect, visibleFrame: CGRect) {
        self.id = id
        self.frame = frame
        self.visibleFrame = visibleFrame
    }
}

public protocol ScreenProvider: AnyObject {
    func getScreens() -> [ScreenDescriptor]
}

public final class AppKitScreenProvider: ScreenProvider {
    public init() {}
    
    public func getScreens() -> [ScreenDescriptor] {
        return NSScreen.screens.enumerated().map { index, screen in
            let id: String
            if let num = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
                id = "\(num.uint32Value)"
            } else {
                id = "display_\(index)_\(Int(screen.frame.origin.x))_\(Int(screen.frame.origin.y))"
            }
            return ScreenDescriptor(id: id, frame: screen.frame, visibleFrame: screen.visibleFrame)
        }
    }
}

public protocol OverlayWindowFactory: AnyObject {
    func createWindow(for screen: ScreenDescriptor, content: NSView) -> NSWindow
}

public final class DefaultOverlayWindowFactory: OverlayWindowFactory {
    public init() {}
    
    public func createWindow(for screen: ScreenDescriptor, content: NSView) -> NSWindow {
        let window = BreakOverlayWindow(
            contentRect: screen.frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.setFrame(screen.frame, display: true)
        window.level = .modalPanel
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.isReleasedWhenClosed = false
        window.contentView = content
        return window
    }
}

public final class BreakOverlayWindow: NSWindow {
    public override var canBecomeKey: Bool { true }
    public override var canBecomeMain: Bool { true }
}

public protocol BreakWindowManaging: AnyObject {
    var isShowingOverlay: Bool { get }
    var activeWindowCount: Int { get }
    func showBreakOverlay(timerManager: TimerManager)
    func hideBreakOverlay()
    func handleScreenParametersChanged(timerManager: TimerManager?)
}

public final class BreakWindowManager: BreakWindowManaging {
    public static let shared = BreakWindowManager()
    
    private let screenProvider: ScreenProvider
    private let windowFactory: OverlayWindowFactory
    private let settings: AppSettings
    
    private var windows: [String: NSWindow] = [:]
    private weak var currentTimerManager: TimerManager?
    
    public private(set) var isShowingOverlay: Bool = false
    
    public var activeWindowCount: Int {
        windows.count
    }
    
    public init(
        screenProvider: ScreenProvider = AppKitScreenProvider(),
        windowFactory: OverlayWindowFactory = DefaultOverlayWindowFactory(),
        settings: AppSettings = .shared
    ) {
        self.screenProvider = screenProvider
        self.windowFactory = windowFactory
        self.settings = settings
        
        setupScreenNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        hideBreakOverlay()
    }
    
    private func setupScreenNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChangedNotification),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    @objc private func screenParametersChangedNotification() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.handleScreenParametersChanged(timerManager: self.currentTimerManager)
        }
    }
    
    public func showBreakOverlay(timerManager: TimerManager) {
        self.currentTimerManager = timerManager
        self.isShowingOverlay = true
        
        reconcileWindows(timerManager: timerManager)
    }
    
    public func hideBreakOverlay() {
        self.isShowingOverlay = false
        self.currentTimerManager = nil
        
        for (_, window) in windows {
            window.orderOut(nil)
            window.contentView = nil
            window.close()
        }
        windows.removeAll()
    }
    
    public func handleScreenParametersChanged(timerManager: TimerManager?) {
        guard isShowingOverlay, let timer = timerManager ?? currentTimerManager else {
            return
        }
        reconcileWindows(timerManager: timer)
    }
    
    // MARK: - Reconcile active screens with active windows
    
    private func reconcileWindows(timerManager: TimerManager) {
        let screens = screenProvider.getScreens()
        
        // If settings specify only main display, filter to primary
        let targetScreens: [ScreenDescriptor]
        if settings.allDisplays {
            targetScreens = screens
        } else {
            if let first = screens.first {
                targetScreens = [first]
            } else {
                targetScreens = []
            }
        }
        
        let targetIds = Set(targetScreens.map { $0.id })
        
        // Remove windows for disconnected screens
        for (screenId, window) in windows where !targetIds.contains(screenId) {
            window.orderOut(nil)
            window.contentView = nil
            window.close()
            windows.removeValue(forKey: screenId)
        }
        
        // Add or update windows for active screens
        for screen in targetScreens {
            if let existingWindow = windows[screen.id] {
                // Ensure frame is accurate if resolution or position changed
                if existingWindow.frame != screen.frame {
                    existingWindow.setFrame(screen.frame, display: true)
                }
                existingWindow.makeKeyAndOrderFront(nil)
            } else {
                // Create new overlay window
                let hostingView = NSHostingView(
                    rootView: BreakScreenView(
                        timerManager: timerManager,
                        appSettings: settings
                    )
                )
                let window = windowFactory.createWindow(for: screen, content: hostingView)
                windows[screen.id] = window
                window.makeKeyAndOrderFront(nil)
            }
        }
        
        // Bring app to front if needed
        NSApp.activate(ignoringOtherApps: true)
    }
}
