import Foundation
import AppKit
import AVFoundation

public protocol SoundManaging: AnyObject {
    func playWorkFinishedSound()
    func playBreakFinishedSound()
}

public final class SoundManager: SoundManaging {
    public static let shared = SoundManager()
    
    private let settings: AppSettings
    
    public init(settings: AppSettings = .shared) {
        self.settings = settings
    }
    
    public func playWorkFinishedSound() {
        guard settings.soundEnabled else { return }
        // NSSound with system sound "Glass" or fallback to AudioServices
        if let sound = NSSound(named: "Glass") {
            sound.play()
        } else {
            NSSound.beep()
        }
    }
    
    public func playBreakFinishedSound() {
        guard settings.soundEnabled else { return }
        // NSSound with system sound "Hero" or fallback
        if let sound = NSSound(named: "Hero") {
            sound.play()
        } else if let fallback = NSSound(named: "Ping") {
            fallback.play()
        } else {
            NSSound.beep()
        }
    }
}
