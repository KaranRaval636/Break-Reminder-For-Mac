import Foundation
import Combine

public protocol NaturalBreakManaging: AnyObject {
    func evaluateUserReturn(idleDuration: TimeInterval)
}

public final class NaturalBreakManager: ObservableObject, NaturalBreakManaging {
    public static let shared = NaturalBreakManager()
    
    private let settings: AppSettings
    private let timerManager: TimerManager
    private let statisticsManager: StatisticsManager
    private let idleProvider: IdleTimeProvider
    
    private var lastObservedIdle: TimeInterval = 0
    private var wasIdle: Bool = false
    private var pollTimer: Timer?
    
    public init(
        settings: AppSettings = .shared,
        timerManager: TimerManager = .shared,
        statisticsManager: StatisticsManager = .shared,
        idleProvider: IdleTimeProvider = SystemIdleTimeProvider()
    ) {
        self.settings = settings
        self.timerManager = timerManager
        self.statisticsManager = statisticsManager
        self.idleProvider = idleProvider
        
        startPolling()
    }
    
    deinit {
        pollTimer?.invalidate()
    }
    
    private func startPolling() {
        pollTimer?.invalidate()
        // Poll idle state every 2 seconds to detect return transition
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkIdleTransition()
        }
    }
    
    public func checkIdleTransition() {
        guard settings.naturalBreakEnabled else { return }
        
        let currentIdle = idleProvider.systemIdleSeconds()
        let threshold = TimeInterval(settings.naturalBreakThresholdSeconds)
        
        // If current idle is large, mark wasIdle = true
        if currentIdle >= threshold {
            wasIdle = true
            lastObservedIdle = currentIdle
        } else if wasIdle && currentIdle < 3.0 {
            // User just returned! (currentIdle plummeted from >= threshold down to < 3s)
            wasIdle = false
            evaluateUserReturn(idleDuration: lastObservedIdle)
            lastObservedIdle = 0
        }
    }
    
    public func evaluateUserReturn(idleDuration: TimeInterval) {
        let threshold = TimeInterval(settings.naturalBreakThresholdSeconds)
        guard idleDuration >= threshold else { return }
        
        // Record natural break in statistics
        statisticsManager.recordNaturalBreak()
        statisticsManager.recordBreakTime(seconds: idleDuration)
        
        // If we were in a work session, reset countdown to avoid an immediate redundant break!
        if timerManager.status == .working || timerManager.status == .paused {
            timerManager.startWorkSession()
        }
    }
}
