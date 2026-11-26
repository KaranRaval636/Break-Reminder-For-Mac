import Foundation

public struct ExcludedApp: Codable, Identifiable, Equatable, Hashable {
    public var id: String { bundleIdentifier }
    public let bundleIdentifier: String
    public let name: String
    
    public init(bundleIdentifier: String, name: String) {
        self.bundleIdentifier = bundleIdentifier
        self.name = name
    }
}

public enum PauseReasonType: String, Codable {
    case idle
    case fullscreen
    case focusApp
    case meeting
    case screenRecording
    case videoPlayback
}

public struct PauseReason: Equatable, Identifiable {
    public var id: String { "\(type.rawValue)_\(detail)" }
    public let type: PauseReasonType
    public let title: String
    public let detail: String
    public let systemImage: String
    
    public init(type: PauseReasonType, title: String, detail: String, systemImage: String) {
        self.type = type
        self.title = title
        self.detail = detail
        self.systemImage = systemImage
    }
}

public struct DetectorDiagnostic: Identifiable, Equatable {
    public var id: String { name }
    public let name: String
    public let isEnabled: Bool
    public let isTriggered: Bool
    public let details: String
    
    public init(name: String, isEnabled: Bool, isTriggered: Bool, details: String) {
        self.name = name
        self.isEnabled = isEnabled
        self.isTriggered = isTriggered
        self.details = details
    }
}
