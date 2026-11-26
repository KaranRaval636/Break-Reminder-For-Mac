import Foundation

public enum BreakProfile: String, CaseIterable, Identifiable, Codable {
    case balanced = "balanced"
    case deepWork = "deepWork"
    case eyeCare = "eyeCare"
    case custom = "custom"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .balanced:
            return "Balanced"
        case .deepWork:
            return "Deep Work"
        case .eyeCare:
            return "Eye Care (20-20-20)"
        case .custom:
            return "Custom"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .balanced:
            return "50m work • 5m short break • 15m long break"
        case .deepWork:
            return "90m work • 15m short break • 30m long break"
        case .eyeCare:
            return "20m work • 1m eye rest • 10m long break"
        case .custom:
            return "Fully personalized work & break intervals"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .balanced:
            return "scale.3d"
        case .deepWork:
            return "brain.head.profile"
        case .eyeCare:
            return "eye.fill"
        case .custom:
            return "slider.horizontal.3"
        }
    }
    
    public var defaultWorkMinutes: Int {
        switch self {
        case .balanced: return 50
        case .deepWork: return 90
        case .eyeCare: return 20
        case .custom: return 50
        }
    }
    
    public var defaultShortBreakMinutes: Int {
        switch self {
        case .balanced: return 5
        case .deepWork: return 15
        case .eyeCare: return 1
        case .custom: return 5
        }
    }
    
    public var defaultLongBreakMinutes: Int {
        switch self {
        case .balanced: return 15
        case .deepWork: return 30
        case .eyeCare: return 10
        case .custom: return 15
        }
    }
    
    public var defaultLongBreakFrequency: Int {
        switch self {
        case .balanced: return 4
        case .deepWork: return 2
        case .eyeCare: return 6
        case .custom: return 4
        }
    }
}
