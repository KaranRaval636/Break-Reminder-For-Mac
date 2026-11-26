import Foundation
import AppKit
import AVFoundation

public enum WellnessSoundPreset: String, CaseIterable, Identifiable {
    case bell = "Bell"
    case chime = "Chime"
    case ping = "Ping"
    case tink = "Tink"
    case submarine = "Submarine"
    case silent = "Silent"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .bell: return "Crystal Bell (Glass)"
        case .chime: return "Harmonic Chime (Hero)"
        case .ping: return "Gentle Ping (Ping)"
        case .tink: return "Subtle Droplet (Tink)"
        case .submarine: return "Deep Resonant (Submarine)"
        case .silent: return "Mute / Silent"
        }
    }
    
    public var systemSoundName: String? {
        switch self {
        case .bell: return "Glass"
        case .chime: return "Hero"
        case .ping: return "Ping"
        case .tink: return "Tink"
        case .submarine: return "Submarine"
        case .silent: return nil
        }
    }
}

public protocol SoundManaging: AnyObject {
    func playWorkFinishedSound()
    func playBreakFinishedSound()
    func playPreview(preset: WellnessSoundPreset)
}

public extension SoundManaging {
    func playPreview(preset: WellnessSoundPreset) {}
}

public final class SoundManager: SoundManaging {
    public static let shared = SoundManager()
    
    private let settings: AppSettings
    
    public init(settings: AppSettings = .shared) {
        self.settings = settings
    }
    
    public func playWorkFinishedSound() {
        guard settings.soundEnabled else { return }
        
        let preset = WellnessSoundPreset(rawValue: settings.soundName) ?? .bell
        guard let soundName = preset.systemSoundName else { return }
        
        if let sound = NSSound(named: soundName) {
            sound.play()
        } else {
            NSSound.beep()
        }
    }
    
    public func playBreakFinishedSound() {
        guard settings.soundEnabled else { return }
        
        // Break finished plays a bright chime or fallback
        if let sound = NSSound(named: "Hero") {
            sound.play()
        } else if let fallback = NSSound(named: "Ping") {
            fallback.play()
        } else {
            NSSound.beep()
        }
    }
    
    public func playPreview(preset: WellnessSoundPreset) {
        guard let name = preset.systemSoundName else { return }
        if let sound = NSSound(named: name) {
            sound.stop()
            sound.play()
        } else {
            NSSound.beep()
        }
    }
}
