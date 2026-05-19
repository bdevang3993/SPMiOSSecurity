import Foundation

public protocol SecurityDetecting: Sendable {
    var threatType: ThreatType { get }
    func scan() async -> [SecurityThreat]
}

public protocol JailbreakDetecting: SecurityDetecting {
    func isJailbroken() -> Bool
}

public protocol RuntimeHookDetecting: SecurityDetecting {
    func isRuntimeHooked() -> Bool
}

public protocol DebuggerDetecting: SecurityDetecting {
    func isDebuggerAttached() -> Bool
    func denyDebuggerAttach()
}

public protocol IntegrityVerifying: SecurityDetecting {
    func verifyIntegrity() -> Bool
}

public protocol ReverseEngineeringDetecting: SecurityDetecting {
    func isReverseEngineeringEnvironmentDetected() -> Bool
}

public protocol SimulatorDetecting: Sendable {
    func isSimulator() -> Bool
}

public protocol NetworkDetecting: SecurityDetecting {
    func isWifiUnsecure() async -> Bool
    func isHotspotActive() async -> Bool
    func isVPNActive() -> Bool
}

public protocol ScreenDetecting: SecurityDetecting {
    func isScreenCaptured() -> Bool
}
