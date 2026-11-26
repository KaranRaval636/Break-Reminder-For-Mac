import Foundation
import Combine

public protocol OfficeHoursManaging: AnyObject {
    var isOutsideOfficeHours: Bool { get }
    func evaluateOfficeHours(currentDate: Date)
    func isWithinOfficeHours(date: Date) -> Bool
}

public final class OfficeHoursManager: ObservableObject, OfficeHoursManaging {
    public static let shared = OfficeHoursManager()
    
    private let settings: AppSettings
    private let timerManager: TimerManager
    private var ticker: Timer?
    
    @Published public private(set) var isOutsideOfficeHours: Bool = false
    
    public init(
        settings: AppSettings = .shared,
        timerManager: TimerManager = .shared
    ) {
        self.settings = settings
        self.timerManager = timerManager
        
        startTicker()
        evaluateOfficeHours()
    }
    
    deinit {
        ticker?.invalidate()
    }
    
    private func startTicker() {
        ticker?.invalidate()
        // Check every 60 seconds
        ticker = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.evaluateOfficeHours()
        }
    }
    
    public func evaluateOfficeHours(currentDate: Date = Date()) {
        guard settings.officeHoursEnabled && !settings.officeHoursOverride else {
            if isOutsideOfficeHours {
                isOutsideOfficeHours = false
                if timerManager.status == .paused {
                    timerManager.resumeTimer()
                }
            }
            return
        }
        
        let inHours = isWithinOfficeHours(date: currentDate)
        if !inHours {
            if !isOutsideOfficeHours {
                isOutsideOfficeHours = true
                if timerManager.status == .working {
                    timerManager.pauseTimer()
                }
            }
        } else {
            if isOutsideOfficeHours {
                isOutsideOfficeHours = false
                if timerManager.status == .paused {
                    timerManager.resumeTimer()
                }
            }
        }
    }
    
    public func isWithinOfficeHours(date: Date = Date()) -> Bool {
        guard settings.officeHoursEnabled && !settings.officeHoursOverride else {
            return true
        }
        
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        guard settings.officeHoursDays.contains(weekday) else {
            return false
        }
        
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let currentMinutes = hour * 60 + minute
        
        let startMinutes = settings.officeHoursStartHour * 60 + settings.officeHoursStartMinute
        let endMinutes = settings.officeHoursEndHour * 60 + settings.officeHoursEndMinute
        
        return currentMinutes >= startMinutes && currentMinutes <= endMinutes
    }
}
