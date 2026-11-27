import Foundation
import Combine
import AppKit

public final class TimerManager: ObservableObject {
    public static let shared = TimerManager()
    
    // Dependencies
    private let settings: AppSettings
    private let soundManager: SoundManaging
    private let notificationManager: NotificationManaging
    private let statisticsManager: StatisticsManaging
    private let breakWindowManager: BreakWindowManaging
    private let defaults: UserDefaults
    
    private let stateStorageKey = "BreakReminder_SavedTimerState_v1"
    
    // Timer Engine
    private var ticker: AnyCancellable?
    
    // Published State
    @Published public private(set) var status: TimerStatus = .idle
    @Published public private(set) var remainingSeconds: TimeInterval = 0
    @Published public private(set) var totalDurationSeconds: TimeInterval = 0
    @Published public private(set) var targetEndDate: Date?
    @Published public private(set) var completedWorkSessionsInCycle: Int = 0
    @Published public private(set) var isLongBreak: Bool = false
    @Published public private(set) var sessionStartDate: Date?
    @Published public private(set) var currentSnoozeCount: Int = 0
    @Published public private(set) var isBreakInBackground: Bool = false
    
    // Smart Pause integration
    @Published public private(set) var isSmartPaused: Bool = false
    @Published public private(set) var smartPauseReason: String? = nil
    
    // Internal state
    private var pausedRemainingSeconds: TimeInterval?
    private var hasSentPreBreakNotification: Bool = false
    
    public var progressFraction: Double {
        guard totalDurationSeconds > 0 else { return 0.0 }
        let elapsed = totalDurationSeconds - remainingSeconds
        return max(0.0, min(1.0, elapsed / totalDurationSeconds))
    }
    
    public var canSnooze: Bool {
        guard settings.allowSnooze && !settings.strictMode else { return false }
        if settings.snoozeLimit > 0 {
            return currentSnoozeCount < settings.snoozeLimit
        }
        return true
    }
    
    public var remainingSnoozes: Int? {
        guard settings.allowSnooze && !settings.strictMode else { return 0 }
        if settings.snoozeLimit > 0 {
            return max(0, settings.snoozeLimit - currentSnoozeCount)
        }
        return nil // unlimited
    }
    
    public var canSkip: Bool {
        return settings.allowSkip && !settings.strictMode
    }
    
    public var canContinueBreakInBackground: Bool {
        guard (status == .onBreak || isBreakInBackground) && !settings.strictMode else { return false }
        return settings.allowScreenAccessDuringBreak
    }
    
    public init(
        settings: AppSettings = .shared,
        soundManager: SoundManaging = SoundManager.shared,
        notificationManager: NotificationManaging = NotificationManager.shared,
        statisticsManager: StatisticsManaging = StatisticsManager.shared,
        breakWindowManager: BreakWindowManaging = BreakWindowManager.shared,
        defaults: UserDefaults = .standard
    ) {
        self.settings = settings
        self.soundManager = soundManager
        self.notificationManager = notificationManager
        self.statisticsManager = statisticsManager
        self.breakWindowManager = breakWindowManager
        self.defaults = defaults
        
        setupSystemObservers()
        restorePersistedState()
        
        if let notifMgr = notificationManager as? NotificationManager {
            notifMgr.onStartWorkSessionRequested = { [weak self] in
                self?.startWorkSession()
            }
        }
        
        if status == .idle && settings.autoStartWorkTimer {
            startWorkSession()
        }
    }
    
    deinit {
        stopTicker()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - System Sleep / Wake Observers
    
    private func setupSystemObservers() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleWorkspaceWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleWorkspaceDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }
    
    @objc private func handleWorkspaceWillSleep() {
        saveState()
    }
    
    @objc private func handleWorkspaceDidWake() {
        // Re-evaluate wall clock time upon waking
        tick()
    }
    
    public func handleSystemSleep() {
        saveState()
    }
    
    public func handleSystemWake() {
        tick()
    }
    
    // MARK: - Timer Actions
    
    public func startWorkSession() {
        stopTicker()
        breakWindowManager.hideBreakOverlay()
        
        let duration = TimeInterval(settings.workIntervalMinutes * 60)
        let now = Date()
        
        status = .working
        totalDurationSeconds = duration
        remainingSeconds = duration
        targetEndDate = now.addingTimeInterval(duration)
        sessionStartDate = now
        pausedRemainingSeconds = nil
        isLongBreak = false
        isBreakInBackground = false
        currentSnoozeCount = 0
        hasSentPreBreakNotification = false
        
        notificationManager.requestAuthorizationIfNeeded()
        saveState()
        AutomationHookManager.shared.handleEvent(.workSessionStarted)
        startTicker()
    }
    
    public func pauseTimer() {
        guard status == .working || status == .onBreak else { return }
        
        recalculateRemaining()
        pausedRemainingSeconds = remainingSeconds
        status = .paused
        targetEndDate = nil
        
        stopTicker()
        saveState()
    }
    
    public func resumeTimer() {
        guard status == .paused, let pausedRemainder = pausedRemainingSeconds else { return }
        
        let now = Date()
        targetEndDate = now.addingTimeInterval(pausedRemainder)
        remainingSeconds = pausedRemainder
        
        // Return to whichever mode was active
        if isLongBreak || breakWindowManager.isShowingOverlay {
            status = .onBreak
        } else {
            status = .working
        }
        
        pausedRemainingSeconds = nil
        saveState()
        startTicker()
    }
    
    public func startBreak(isLong: Bool? = nil, durationMinutes: Int? = nil) {
        stopTicker()
        
        let shouldBeLong = isLong ?? (completedWorkSessionsInCycle >= settings.longBreakFrequency)
        isLongBreak = shouldBeLong
        
        let minutes: Int
        if let customMinutes = durationMinutes {
            minutes = customMinutes
        } else {
            minutes = shouldBeLong ? settings.longBreakMinutes : settings.shortBreakMinutes
        }
        
        let duration = TimeInterval(minutes * 60)
        let now = Date()
        
        status = .onBreak
        totalDurationSeconds = duration
        remainingSeconds = duration
        targetEndDate = now.addingTimeInterval(duration)
        sessionStartDate = now
        pausedRemainingSeconds = nil
        isBreakInBackground = false
        hasSentPreBreakNotification = false
        
        soundManager.playWorkFinishedSound()
        notificationManager.sendWorkFinishedNotification(isLongBreak: shouldBeLong)
        breakWindowManager.showBreakOverlay(timerManager: self)
        
        saveState()
        AutomationHookManager.shared.handleEvent(.breakStarted(isLong: shouldBeLong))
        startTicker()
    }
    
    public func startBreakImmediately(durationMinutes: Int? = nil) {
        // Record partial work session time if we were working
        if status == .working, let start = sessionStartDate {
            let elapsed = Date().timeIntervalSince(start)
            statisticsManager.recordWorkTime(seconds: elapsed)
        }
        startBreak(isLong: durationMinutes != nil ? false : nil, durationMinutes: durationMinutes)
    }
    
    public func startImmediateBreak(durationMinutes: Int? = nil) {
        startBreakImmediately(durationMinutes: durationMinutes)
    }
    
    public func skipBreak() {
        guard (status == .onBreak || status == .paused) && canSkip else { return }
        
        stopTicker()
        breakWindowManager.hideBreakOverlay()
        statisticsManager.recordBreakSkipped()
        
        // If it was a long break, reset cycle
        if isLongBreak {
            completedWorkSessionsInCycle = 0
        }
        currentSnoozeCount = 0
        isBreakInBackground = false
        
        AutomationHookManager.shared.handleEvent(.breakSkipped)
        resetToIdle()
        saveState()
    }
    
    public func snoozeBreak() {
        guard canSnooze else { return }
        
        stopTicker()
        breakWindowManager.hideBreakOverlay()
        currentSnoozeCount += 1
        
        let snoozeDuration = TimeInterval(settings.snoozeDurationMinutes * 60)
        let now = Date()
        
        status = .working // Snooze acts as a brief extension of working time
        totalDurationSeconds = snoozeDuration
        remainingSeconds = snoozeDuration
        targetEndDate = now.addingTimeInterval(snoozeDuration)
        sessionStartDate = now
        pausedRemainingSeconds = nil
        isBreakInBackground = false
        hasSentPreBreakNotification = false
        
        saveState()
        startTicker()
    }
    
    public func completeBreakEarly() {
        guard status == .onBreak else { return }
        
        if let start = sessionStartDate {
            let elapsed = Date().timeIntervalSince(start)
            statisticsManager.recordBreakCompleted(duration: elapsed)
        }
        
        handleBreakFinished()
    }
    
    public func continueBreakInBackground() {
        guard status == .onBreak && canContinueBreakInBackground else { return }
        isBreakInBackground = true
        breakWindowManager.hideBreakOverlay()
        saveState()
    }
    
    public func showBreakOverlay() {
        guard status == .onBreak else { return }
        isBreakInBackground = false
        breakWindowManager.showBreakOverlay(timerManager: self)
        saveState()
    }
    
    public func resetTimer() {
        stopTicker()
        breakWindowManager.hideBreakOverlay()
        notificationManager.cancelPendingNotifications()
        currentSnoozeCount = 0
        isSmartPaused = false
        smartPauseReason = nil
        resetToIdle()
        clearSavedState()
    }
    
    // MARK: - Smart Pause Integration
    
    public func applySmartPause(reason: String) {
        guard !isSmartPaused else { return }
        isSmartPaused = true
        smartPauseReason = reason
        
        AutomationHookManager.shared.handleEvent(.smartPauseActivated(reason: reason))
        
        if status == .working {
            pauseTimer()
        }
    }
    
    public func resumeFromSmartPause() {
        guard isSmartPaused else { return }
        isSmartPaused = false
        smartPauseReason = nil
        
        AutomationHookManager.shared.handleEvent(.smartPauseDeactivated)
        
        if status == .paused {
            resumeTimer()
        }
    }
    
    private func resetToIdle() {
        status = .idle
        targetEndDate = nil
        remainingSeconds = 0
        totalDurationSeconds = 0
        pausedRemainingSeconds = nil
        sessionStartDate = nil
        isBreakInBackground = false
        hasSentPreBreakNotification = false
    }
    
    // MARK: - Internal Ticker & Countdown Logic
    
    private func startTicker() {
        stopTicker()
        ticker = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }
    
    private func stopTicker() {
        ticker?.cancel()
        ticker = nil
    }
    
    public func tick(currentDate: Date = Date()) {
        guard status == .working || status == .onBreak else { return }
        guard let target = targetEndDate else { return }
        
        let remaining = target.timeIntervalSince(currentDate)
        
        // Check for pre-break notification
        if status == .working && settings.preBreakNotificationEnabled && !hasSentPreBreakNotification {
            let leadSeconds = TimeInterval(settings.preBreakNotificationLeadMinutes * 60)
            if remaining > 0 && remaining <= leadSeconds {
                hasSentPreBreakNotification = true
                notificationManager.sendPreBreakNotification(minutesRemaining: settings.preBreakNotificationLeadMinutes)
            }
        }
        
        if remaining <= 0 {
            remainingSeconds = 0
            handleTimerCompleted()
        } else {
            remainingSeconds = remaining
        }
    }
    
    private func recalculateRemaining(currentDate: Date = Date()) {
        if let target = targetEndDate {
            remainingSeconds = max(0, target.timeIntervalSince(currentDate))
        }
    }
    
    private func handleTimerCompleted() {
        stopTicker()
        
        switch status {
        case .working:
            handleWorkSessionFinished()
        case .onBreak:
            handleBreakFinished()
        default:
            break
        }
    }
    
    private func handleWorkSessionFinished() {
        completedWorkSessionsInCycle += 1
        
        let workDuration = totalDurationSeconds
        statisticsManager.recordWorkSessionCompleted(duration: workDuration)
        
        if settings.autoStartBreaks {
            let isNextLong = completedWorkSessionsInCycle >= settings.longBreakFrequency
            startBreak(isLong: isNextLong)
        } else {
            soundManager.playWorkFinishedSound()
            notificationManager.sendWorkFinishedNotification(
                isLongBreak: completedWorkSessionsInCycle >= settings.longBreakFrequency
            )
            resetToIdle()
            saveState()
        }
    }
    
    private func handleBreakFinished() {
        breakWindowManager.hideBreakOverlay()
        soundManager.playBreakFinishedSound()
        notificationManager.sendBreakFinishedNotification()
        AutomationHookManager.shared.handleEvent(.breakEnded)
        
        let wasInBackground = isBreakInBackground
        isBreakInBackground = false
        
        if isLongBreak {
            completedWorkSessionsInCycle = 0
        }
        currentSnoozeCount = 0
        
        if settings.autoStartWorkTimer && !wasInBackground {
            startWorkSession()
        } else {
            resetToIdle()
            saveState()
        }
    }
    
    // MARK: - State Persistence & Recovery
    
    public func saveState() {
        let snapshot = TimerSnapshot(
            status: status,
            targetEndDate: targetEndDate,
            remainingSeconds: remainingSeconds,
            totalDurationSeconds: totalDurationSeconds,
            completedWorkSessionsInCycle: completedWorkSessionsInCycle,
            isLongBreak: isLongBreak,
            pausedRemainingSeconds: pausedRemainingSeconds,
            lastSavedDate: Date(),
            sessionStartDate: sessionStartDate,
            isBreakInBackground: isBreakInBackground
        )
        
        do {
            let data = try JSONEncoder().encode(snapshot)
            defaults.set(data, forKey: stateStorageKey)
        } catch {
            NSLog("[TimerManager] Failed to save timer state: %@", error.localizedDescription)
        }
    }
    
    public func restorePersistedState(currentDate: Date = Date()) {
        guard let data = defaults.data(forKey: stateStorageKey) else { return }
        do {
            let snapshot = try JSONDecoder().decode(TimerSnapshot.self, from: data)
            self.completedWorkSessionsInCycle = snapshot.completedWorkSessionsInCycle
            self.totalDurationSeconds = snapshot.totalDurationSeconds
            self.isLongBreak = snapshot.isLongBreak
            self.sessionStartDate = snapshot.sessionStartDate
            
            switch snapshot.status {
            case .idle:
                resetToIdle()
                
            case .paused:
                self.status = .paused
                self.pausedRemainingSeconds = snapshot.pausedRemainingSeconds
                self.remainingSeconds = snapshot.pausedRemainingSeconds ?? 0
                self.targetEndDate = nil
                
            case .working:
                if let target = snapshot.targetEndDate {
                    let diff = target.timeIntervalSince(currentDate)
                    if diff > 0 {
                        self.status = .working
                        self.targetEndDate = target
                        self.remainingSeconds = diff
                        startTicker()
                    } else {
                        // Expired while app was closed
                        completedWorkSessionsInCycle += 1
                        statisticsManager.recordWorkSessionCompleted(duration: snapshot.totalDurationSeconds)
                        resetToIdle()
                    }
                } else {
                    resetToIdle()
                }
                
            case .onBreak:
                if let target = snapshot.targetEndDate {
                    let diff = target.timeIntervalSince(currentDate)
                    if diff > 0 {
                        self.status = .onBreak
                        self.targetEndDate = target
                        self.remainingSeconds = diff
                        self.isBreakInBackground = snapshot.isBreakInBackground
                        if !snapshot.isBreakInBackground {
                            breakWindowManager.showBreakOverlay(timerManager: self)
                        }
                        startTicker()
                    } else {
                        // Break expired while app was closed
                        if isLongBreak {
                            completedWorkSessionsInCycle = 0
                        }
                        resetToIdle()
                    }
                } else {
                    resetToIdle()
                }
            }
        } catch {
            NSLog("[TimerManager] Failed to restore timer state: %@", error.localizedDescription)
            resetToIdle()
        }
    }
    
    public func clearSavedState() {
        defaults.removeObject(forKey: stateStorageKey)
    }
}
