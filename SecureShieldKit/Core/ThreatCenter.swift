import Foundation

public final class ThreatCenter: @unchecked Sendable {
    public static let shared = ThreatCenter()

    private let lock = NSLock()
    private var handlers: [UUID: ThreatHandler] = [:]
    private var recentThreats: [SecurityThreat] = []
    private let maximumRetainedThreats = 128

    public init() {}

    @discardableResult
    public func register(_ handler: @escaping ThreatHandler) -> UUID {
        let id = UUID()
        lock.withLock {
            handlers[id] = handler
        }
        return id
    }

    public func unregister(_ id: UUID) {
        lock.withLock {
            handlers.removeValue(forKey: id)
        }
    }

    public func report(_ threat: SecurityThreat) {
        let currentHandlers: [ThreatHandler] = lock.withLock {
            recentThreats.append(threat)
            if recentThreats.count > maximumRetainedThreats {
                recentThreats.removeFirst(recentThreats.count - maximumRetainedThreats)
            }
            return Array(handlers.values)
        }

        for handler in currentHandlers {
            print("[SecureShieldKit] Threat reported: \(threat.type.rawValue) (Level: \(threat.level.rawValue))")
            DispatchQueue.global(qos: .utility).async {
                handler(threat)
            }
        }
    }

    public func history() -> [SecurityThreat] {
        lock.withLock { recentThreats }
    }
}
