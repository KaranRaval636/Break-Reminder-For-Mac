import Foundation

public enum NavigationSection: String, CaseIterable, Identifiable {
    case dashboard = "dashboard"
    case screenBreaks = "screenBreaks"
    case smartPause = "smartPause"
    case wellness = "wellness"
    case plannedBreaks = "plannedBreaks"
    case officeHours = "officeHours"
    case statistics = "statistics"
    case appearance = "appearance"
    case automations = "automations"
    case generalSettings = "generalSettings"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .screenBreaks: return "Screen Breaks"
        case .smartPause: return "Smart Pause"
        case .wellness: return "Wellness Reminders"
        case .plannedBreaks: return "Planned Breaks"
        case .officeHours: return "Office Hours"
        case .statistics: return "Statistics & Score"
        case .appearance: return "Appearance"
        case .automations: return "Automations"
        case .generalSettings: return "General Settings"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .dashboard: return "gauge.with.dots.needle.bottom.50percent"
        case .screenBreaks: return "cup.and.saucer.fill"
        case .smartPause: return "brain.head.profile"
        case .wellness: return "eye.fill"
        case .plannedBreaks: return "calendar.badge.clock"
        case .officeHours: return "briefcase.fill"
        case .statistics: return "chart.xyaxis.line"
        case .appearance: return "paintbrush.fill"
        case .automations: return "bolt.fill"
        case .generalSettings: return "gearshape.fill"
        }
    }
}
