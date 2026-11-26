import Foundation
import Combine

public protocol PlannedBreakManaging: AnyObject {
    func evaluatePlannedBreaks(currentDate: Date)
    func addPlannedBreak(_ item: PlannedBreak)
    func removePlannedBreak(id: UUID)
    func togglePlannedBreak(id: UUID)
}

public final class PlannedBreakManager: ObservableObject, PlannedBreakManaging {
    public static let shared = PlannedBreakManager()
    
    private let settings: AppSettings
    private let timerManager: TimerManager
    private let smartPauseManager: SmartPauseManager
    
    private var minuteTicker: Timer?
    private var lastTriggeredBreakId: UUID?
    private var lastTriggeredMinute: Int = -1
    
    public init(
        settings: AppSettings = .shared,
        timerManager: TimerManager = .shared,
        smartPauseManager: SmartPauseManager = .shared
    ) {
        self.settings = settings
        self.timerManager = timerManager
        self.smartPauseManager = smartPauseManager
        
        startTicker()
    }
    
    deinit {
        minuteTicker?.invalidate()
    }
    
    private func startTicker() {
        minuteTicker?.invalidate()
        // Check every 30 seconds
        minuteTicker = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.evaluatePlannedBreaks()
        }
    }
    
    public func evaluatePlannedBreaks(currentDate: Date = Date()) {
        guard !settings.plannedBreaks.isEmpty else { return }
        guard timerManager.status != .onBreak else { return } // Avoid overlapping break windows
        guard !smartPauseManager.isSmartPaused else { return } // Respect smart pause
        
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: currentDate)
        let currentHour = calendar.component(.hour, from: currentDate)
        let currentMinute = calendar.component(.minute, from: currentDate)
        
        // Prevent duplicate trigger within the same minute
        if currentMinute == lastTriggeredMinute { return }
        
        for item in settings.plannedBreaks where item.isEnabled {
            if item.repeatDays.contains(currentWeekday) && item.hour == currentHour && item.minute == currentMinute {
                lastTriggeredBreakId = item.id
                lastTriggeredMinute = currentMinute
                
                // Start planned break with higher priority
                timerManager.startBreakImmediately(durationMinutes: item.durationMinutes)
                break
            }
        }
    }
    
    public func addPlannedBreak(_ item: PlannedBreak) {
        settings.plannedBreaks.append(item)
    }
    
    public func removePlannedBreak(id: UUID) {
        settings.plannedBreaks.removeAll(where: { $0.id == id })
    }
    
    public func togglePlannedBreak(id: UUID) {
        if let idx = settings.plannedBreaks.firstIndex(where: { $0.id == id }) {
            settings.plannedBreaks[idx].isEnabled.toggle()
        }
    }
}
