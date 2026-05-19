import Foundation

public enum ThreatLevel: String, Sendable, Codable {
    case low
    case medium
    case high
    case critical
}

public enum ThreatType: String, Sendable, Codable, CaseIterable {
    case jailbreak
    case jailbreakBypass
    case runtimeHook
    case frida
    case debugger
    case integrityViolation
    case reverseEngineering
    case simulator
    case sslPinningFailure
    case tampering
    case unsecureWifi
    case unsecureHotspot
    case vpnActive
    case screenCaptured
}

public struct SecurityThreat: Sendable, Codable, Equatable {
    public let type: ThreatType
    public let level: ThreatLevel
    public let timestamp: Date
    public let metadata: [String: String]

    public init(
        type: ThreatType,
        level: ThreatLevel,
        timestamp: Date = Date(),
        metadata: [String: String] = [:]
    ) {
        self.type = type
        self.level = level
        self.timestamp = timestamp
        self.metadata = metadata
    }
}

public typealias ThreatHandler = @Sendable (SecurityThreat) -> Void
