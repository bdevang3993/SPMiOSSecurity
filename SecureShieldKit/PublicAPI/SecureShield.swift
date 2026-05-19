import Foundation

public enum SecureShield {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var engine: SecureShieldEngine = SecureShieldEngine(configuration: .production)

    public static func configure(_ configuration: SecureShieldConfiguration) {
        lock.withLock {
            engine.stop()
            engine = SecureShieldEngine(configuration: configuration)
        }
    }

    public static func start() {
        let engine = currentEngine()
        engine.start()
        
        MixpanelTracker.track(
            event: "SecureShield Started",
            token: engine.configuration.mixpanelToken
        )
    }

    public static func trackEvent(_ event: String, properties: [String: Any] = [:]) {
        let engine = currentEngine()
        MixpanelTracker.track(
            event: event,
            token: engine.configuration.mixpanelToken,
            properties: properties
        )
    }

    public static func stop() {
        currentEngine().stop()
    }

    public static func isJailbroken() -> Bool {
        currentEngine().jailbreakDetector.isJailbroken()
    }

    public static func isRuntimeHooked() -> Bool {
        currentEngine().hookDetector.isRuntimeHooked()
    }

    public static func isDebuggerAttached() -> Bool {
        currentEngine().debuggerDetector.isDebuggerAttached()
    }

    public static func verifyIntegrity() -> Bool {
        currentEngine().integrityVerifier.verifyIntegrity()
    }

    public static func isSimulator() -> Bool {
        currentEngine().simulatorDetector.isSimulator()
    }

    public static func isWifiUnsecure() async -> Bool {
        await currentEngine().networkDetector.isWifiUnsecure()
    }

    public static func isHotspotActive() async -> Bool {
        await currentEngine().networkDetector.isHotspotActive()
    }

    public static func isVPNActive() -> Bool {
        currentEngine().networkDetector.isVPNActive()
    }

    public static func isAppInstalled(scheme: String) -> Bool {
        AppDetector.isInstalled(scheme: scheme)
    }

    public static func installedAppSchemes() -> [String] {
        AppDetector.installedSchemes(from: currentEngine().configuration.monitoredAppSchemes)
    }

    public static func scanForThreats() async -> [SecurityThreat] {
        await currentEngine().scanAll()
    }

    public static func isJailbrokenAsync() async -> Bool {
        await !currentEngine().jailbreakDetector.scan().isEmpty
    }

    public static func isRuntimeHookedAsync() async -> Bool {
        await !currentEngine().hookDetector.scan().isEmpty
    }

    public static func isDebuggerAttachedAsync() async -> Bool {
        await !currentEngine().debuggerDetector.scan().isEmpty
    }

    public static func verifyIntegrityAsync() async -> Bool {
        await currentEngine().integrityVerifier.scan().isEmpty
    }

    @discardableResult
    public static func onThreatDetected(_ handler: @escaping ThreatHandler) -> UUID {
        currentEngine().threatCenter.register(handler)
    }

    public static func removeThreatHandler(_ id: UUID) {
        currentEngine().threatCenter.unregister(id)
    }

    public static func enableSSLPinning(
        certificates: [Data] = [],
        publicKeys: [Data] = []
    ) {
        SSLPinning.shared.configure(certificates: certificates, publicKeys: publicKeys)
    }

    public static func makePinnedURLSession(
        configuration: URLSessionConfiguration = .ephemeral
    ) -> URLSession {
        SSLPinning.shared.makeURLSession(configuration: configuration)
    }

    public static func deviceTrustService() -> DeviceTrustService {
        DeviceTrustService()
    }

    private static func currentEngine() -> SecureShieldEngine {
        lock.withLock { engine }
    }
}
