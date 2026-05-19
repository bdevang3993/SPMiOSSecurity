import Foundation

public final class SecureShieldEngine: @unchecked Sendable {
    public let configuration: SecureShieldConfiguration
    public let jailbreakDetector: JailbreakDetecting
    public let hookDetector: RuntimeHookDetecting
    public let debuggerDetector: DebuggerDetecting
    public let integrityVerifier: IntegrityVerifying
    public let reverseEngineeringDetector: ReverseEngineeringDetecting
    public let simulatorDetector: SimulatorDetecting
    public let networkDetector: NetworkDetecting
    public let screenDetector: ScreenDetecting
    public let threatCenter: ThreatCenter

    private let lock = NSLock()
    private var monitoringTask: Task<Void, Never>?

    public init(
        configuration: SecureShieldConfiguration,
        jailbreakDetector: JailbreakDetecting = JailbreakDetector(),
        hookDetector: RuntimeHookDetecting = RuntimeHookDetector(),
        debuggerDetector: DebuggerDetecting = AntiDebugDetector(),
        integrityVerifier: IntegrityVerifying? = nil,
        reverseEngineeringDetector: ReverseEngineeringDetecting = ReverseEngineeringDetector(),
        simulatorDetector: SimulatorDetecting = SimulatorDetector(),
        networkDetector: NetworkDetecting = NetworkDetector(),
        screenDetector: ScreenDetecting = ScreenDetector(),
        threatCenter: ThreatCenter = .shared
    ) {
        self.configuration = configuration
        self.jailbreakDetector = jailbreakDetector
        self.hookDetector = hookDetector
        self.debuggerDetector = debuggerDetector
        self.integrityVerifier = integrityVerifier ?? IntegrityVerifier(configuration: configuration)
        self.reverseEngineeringDetector = reverseEngineeringDetector
        self.simulatorDetector = simulatorDetector
        self.networkDetector = networkDetector
        self.screenDetector = screenDetector
        self.threatCenter = threatCenter
    }

    public func start() {
        debuggerDetector.denyDebuggerAttach()
        guard configuration.enableRuntimeMonitoring else { return }

        lock.withLock {
            guard monitoringTask == nil else { return }
            monitoringTask = Task.detached(priority: .utility) { [weak self] in
                await self?.monitor()
            }
        }
    }

    public func stop() {
        lock.withLock {
            monitoringTask?.cancel()
            monitoringTask = nil
        }
    }

    public func scanAll() async -> [SecurityThreat] {
        async let jailbreak = jailbreakDetector.scan()
        async let hooks = hookDetector.scan()
        async let debug = debuggerDetector.scan()
        async let integrity = integrityVerifier.scan()
        async let reverse = reverseEngineeringDetector.scan()
        async let network = configuration.checkNetworkSecurity ? networkDetector.scan() : []
        async let screen = configuration.checkScreenCapture ? screenDetector.scan() : []

        var threats = await jailbreak + hooks + debug + integrity + reverse + network + screen
        if simulatorDetector.isSimulator() {
            threats.append(SecurityThreat(type: .simulator, level: .low, metadata: ["environment": "simulator"]))
        }
        threats.forEach(threatCenter.report)
        return threats
    }

    private func monitor() async {
        while !Task.isCancelled {
            _ = await scanAll()
            let interval = UInt64(configuration.monitoringInterval * 1_000_000_000)
            try? await Task.sleep(nanoseconds: interval)
        }
    }
}
