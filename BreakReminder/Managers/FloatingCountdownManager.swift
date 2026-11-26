import AppKit
import SwiftUI
import Combine

public final class FloatingCountdownWindow: NSPanel {
    public override var canBecomeKey: Bool { false }
    public override var canBecomeMain: Bool { false }
}

public protocol FloatingCountdownManaging: AnyObject {
    var isVisible: Bool { get }
    func updateVisibility()
    func setPosition(_ position: String)
}

public final class FloatingCountdownManager: NSObject, FloatingCountdownManaging, NSWindowDelegate {
    public static let shared = FloatingCountdownManager()
    
    private let settings: AppSettings
    private let timerManager: TimerManager
    private var window: FloatingCountdownWindow?
    private var cancellables = Set<AnyCancellable>()
    
    private let savedOriginXKey = "BreakReminder_FloatingHUD_X"
    private let savedOriginYKey = "BreakReminder_FloatingHUD_Y"
    
    public var isVisible: Bool {
        window?.isVisible ?? false
    }
    
    public init(
        settings: AppSettings = .shared,
        timerManager: TimerManager = .shared
    ) {
        self.settings = settings
        self.timerManager = timerManager
        super.init()
        
        setupSubscriptions()
        updateVisibility()
    }
    
    deinit {
        window?.orderOut(nil)
        window = nil
    }
    
    private func setupSubscriptions() {
        // Observe timer status and remaining seconds
        timerManager.$status
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateVisibility() }
            .store(in: &cancellables)
        
        timerManager.$remainingSeconds
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateVisibility() }
            .store(in: &cancellables)
        
        // Observe settings changes
        settings.$floatingCountdownEnabled
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateVisibility() }
            .store(in: &cancellables)
            
        settings.$floatingOnlyInPreBreak
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateVisibility() }
            .store(in: &cancellables)
            
        settings.$floatingPosition
            .receive(on: RunLoop.main)
            .sink { [weak self] newPos in self?.setPosition(newPos) }
            .store(in: &cancellables)
    }
    
    public func updateVisibility() {
        guard settings.floatingCountdownEnabled else {
            hideWindow()
            return
        }
        
        // Only show while actively working
        guard timerManager.status == .working else {
            hideWindow()
            return
        }
        
        // Check if restricted to pre-break window
        if settings.floatingOnlyInPreBreak {
            let leadSeconds = TimeInterval(settings.preBreakNotificationLeadMinutes * 60)
            if timerManager.remainingSeconds > leadSeconds {
                hideWindow()
                return
            }
        }
        
        showWindow()
    }
    
    public func showWindow() {
        if window == nil {
            createWindow()
        }
        
        if let win = window, !win.isVisible {
            win.orderFrontRegardless()
        }
    }
    
    public func hideWindow() {
        window?.orderOut(nil)
    }
    
    public func setPosition(_ position: String) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let hudWidth: CGFloat = 154
        let hudHeight: CGFloat = 38
        
        var newOrigin: CGPoint
        switch position {
        case "topLeft":
            newOrigin = CGPoint(x: screenFrame.minX + 24, y: screenFrame.maxY - hudHeight - 24)
        case "bottomRight":
            newOrigin = CGPoint(x: screenFrame.maxX - hudWidth - 24, y: screenFrame.minY + 24)
        case "bottomLeft":
            newOrigin = CGPoint(x: screenFrame.minX + 24, y: screenFrame.minY + 24)
        default: // "topRight" or default
            newOrigin = CGPoint(x: screenFrame.maxX - hudWidth - 24, y: screenFrame.maxY - hudHeight - 24)
        }
        
        window?.setFrameOrigin(newOrigin)
        savePosition(newOrigin)
    }
    
    private func createWindow() {
        let hudView = FloatingCountdownView(timerManager: timerManager, settings: settings)
        let hostingView = NSHostingView(rootView: hudView)
        
        let win = FloatingCountdownWindow(
            contentRect: NSRect(x: 0, y: 0, width: 154, height: 38),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        win.level = .floating
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        win.isOpaque = false
        win.backgroundColor = .clear
        win.hasShadow = false
        win.isMovableByWindowBackground = true
        win.isReleasedWhenClosed = false
        win.delegate = self
        win.contentView = hostingView
        
        // Position
        let initialOrigin = resolveInitialOrigin()
        win.setFrameOrigin(initialOrigin)
        
        self.window = win
    }
    
    private func resolveInitialOrigin() -> CGPoint {
        let defaults = UserDefaults.standard
        let savedX = defaults.object(forKey: savedOriginXKey) as? CGFloat
        let savedY = defaults.object(forKey: savedOriginYKey) as? CGFloat
        
        if let x = savedX, let y = savedY {
            let candidatePoint = CGPoint(x: x, y: y)
            // Verify if candidatePoint is on any connected screen
            for screen in NSScreen.screens {
                if screen.frame.contains(candidatePoint) {
                    return candidatePoint
                }
            }
        }
        
        // Fallback: top right of main screen
        guard let screen = NSScreen.main else {
            return CGPoint(x: 100, y: 100)
        }
        return CGPoint(
            x: screen.visibleFrame.maxX - 154 - 24,
            y: screen.visibleFrame.maxY - 38 - 24
        )
    }
    
    private func savePosition(_ point: CGPoint) {
        UserDefaults.standard.set(point.x, forKey: savedOriginXKey)
        UserDefaults.standard.set(point.y, forKey: savedOriginYKey)
    }
    
    // MARK: - NSWindowDelegate
    
    public func windowDidMove(_ notification: Notification) {
        if let origin = window?.frame.origin {
            savePosition(origin)
        }
    }
}
