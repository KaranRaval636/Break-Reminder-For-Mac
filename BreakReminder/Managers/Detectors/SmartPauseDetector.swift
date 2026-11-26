import Foundation

public protocol SmartPauseDetector: AnyObject {
    var name: String { get }
    var isEnabled: Bool { get }
    func checkPauseCondition() -> PauseReason?
    func currentDiagnostic() -> DetectorDiagnostic
}
