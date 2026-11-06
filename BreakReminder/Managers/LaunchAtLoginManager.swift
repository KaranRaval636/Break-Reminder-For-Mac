import Foundation
import ServiceManagement

public final class LaunchAtLoginManager {
    public static let shared = LaunchAtLoginManager()
    
    public init() {}
    
    public var isAvailable: Bool {
        if #available(macOS 13.0, *) {
            return true
        }
        return false
    }
    
    public var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }
    
    public func setEnabled(_ enabled: Bool) -> Result<Void, Error> {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
                return .success(())
            } catch {
                NSLog("[LaunchAtLoginManager] Error setting launch at login: %@", error.localizedDescription)
                return .failure(error)
            }
        }
        return .success(())
    }
}
