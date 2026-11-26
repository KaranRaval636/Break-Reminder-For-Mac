import Foundation
import AppKit
import Combine

public protocol SmartPauseManaging: AnyObject {
    var isSmartPaused: Bool { get }
    var currentReasons: [PauseReason] { get }
    var primaryReasonText: String? { get }
    var diagnostics: [DetectorDiagnostic] { get }
    func evaluateNow()
    func addExcludedApp(bundleIdentifier: String, name: String)
    func removeExcludedApp(id: String)
}

public final class SmartPauseManager: ObservableObject, SmartPauseManaging {
    public static let shared = SmartPauseManager()
    
    private let settings: AppSettings
    private let timerManager: TimerManager
    
    // Detectors
    public let idleDetector: IdleDetector
    public let activeAppDetector: ActiveApplicationDetector
    public let fullscreenDetector: FullscreenDetector
    public let meetingDetector: MeetingDetector
    public let recordingDetector: ScreenRecordingDetector
    public let videoDetector: VideoPlaybackDetector
    public let focusAppDetector: UserFocusAppDetector
    
    private var allDetectors: [SmartPauseDetector] = []
    private var checkTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    @Published public private(set) var isSmartPaused: Bool = false
    @Published public private(set) var currentReasons: [PauseReason] = []
    @Published public private(set) var primaryReasonText: String? = nil
    @Published public private(set) var diagnostics: [DetectorDiagnostic] = []
    
    public init(
        settings: AppSettings = .shared,
        timerManager: TimerManager = .shared,
        idleDetector: IdleDetector? = nil,
        activeAppDetector: ActiveApplicationDetector? = nil,
        fullscreenDetector: FullscreenDetector? = nil,
        meetingDetector: MeetingDetector? = nil,
        recordingDetector: ScreenRecordingDetector? = nil,
        videoDetector: VideoPlaybackDetector? = nil,
        focusAppDetector: UserFocusAppDetector? = nil
    ) {
        self.settings = settings
        self.timerManager = timerManager
        
        self.idleDetector = idleDetector ?? IdleDetector(settings: settings)
        self.activeAppDetector = activeAppDetector ?? ActiveApplicationDetector(settings: settings)
        self.fullscreenDetector = fullscreenDetector ?? FullscreenDetector(settings: settings)
        self.meetingDetector = meetingDetector ?? MeetingDetector(settings: settings)
        self.recordingDetector = recordingDetector ?? ScreenRecordingDetector(settings: settings)
        self.videoDetector = videoDetector ?? VideoPlaybackDetector(settings: settings)
        self.focusAppDetector = focusAppDetector ?? UserFocusAppDetector(settings: settings)
        
        self.allDetectors = [
            self.meetingDetector,
            self.recordingDetector,
            self.fullscreenDetector,
            self.focusAppDetector,
            self.videoDetector,
            self.idleDetector,
            self.activeAppDetector
        ]
        
        setupWorkspaceObservers()
        startPeriodicCheck()
        evaluateNow()
    }
    
    deinit {
        checkTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupWorkspaceObservers() {
        // Event-driven immediate recheck when active app switches
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleAppActivated),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }
    
    @objc private func handleAppActivated() {
        DispatchQueue.main.async { [weak self] in
            self?.evaluateNow()
        }
    }
    
    private func startPeriodicCheck() {
        checkTimer?.invalidate()
        // Low-overhead periodic timer (2.5 seconds)
        checkTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            self?.evaluateNow()
        }
    }
    
    public func evaluateNow() {
        guard settings.smartPauseEnabled else {
            if isSmartPaused {
                clearSmartPause()
            }
            updateDiagnostics()
            return
        }
        
        var foundReasons: [PauseReason] = []
        for detector in allDetectors {
            if let reason = detector.checkPauseCondition() {
                foundReasons.append(reason)
            }
        }
        
        self.currentReasons = foundReasons
        updateDiagnostics()
        
        if let primary = foundReasons.first {
            let reasonSummary = "\(primary.title): \(primary.detail)"
            self.primaryReasonText = reasonSummary
            self.isSmartPaused = true
            
            // If timer is currently working, coordinate smart pause
            if timerManager.status == .working {
                timerManager.applySmartPause(reason: reasonSummary)
            }
        } else {
            if isSmartPaused {
                clearSmartPause()
            }
        }
    }
    
    private func clearSmartPause() {
        self.isSmartPaused = false
        self.primaryReasonText = nil
        self.currentReasons = []
        
        // Resume timer and adjust remaining seconds if a postponed break was due
        if timerManager.isSmartPaused {
            if timerManager.remainingSeconds <= TimeInterval(settings.smartPausePostponeBufferSeconds) {
                // Give user a generous postponement buffer before overlay appears
                timerManager.snoozeBreak()
            } else {
                timerManager.resumeFromSmartPause()
            }
        }
    }
    
    private func updateDiagnostics() {
        self.diagnostics = allDetectors.map { $0.currentDiagnostic() }
    }
    
    public func addExcludedApp(bundleIdentifier: String, name: String) {
        let trimmedId = bundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedId.isEmpty else { return }
        if !settings.excludedApps.contains(where: { $0.bundleIdentifier == trimmedId }) {
            settings.excludedApps.append(ExcludedApp(bundleIdentifier: trimmedId, name: name))
            evaluateNow()
        }
    }
    
    public func removeExcludedApp(id: String) {
        settings.excludedApps.removeAll(where: { $0.bundleIdentifier == id })
        evaluateNow()
    }
}
