import Foundation

public struct SecureShieldConfiguration: Sendable {
    public var enableRuntimeMonitoring: Bool
    public var monitoringInterval: TimeInterval
    public var failClosedOnPinningError: Bool
    public var expectedTeamIdentifier: String?
    public var expectedBundleIdentifier: String?
    public var expectedExecutableSHA256: String?
    public var encryptedConfiguration: Data?
    public var checkNetworkSecurity: Bool
    public var checkScreenCapture: Bool
    public var monitoredAppSchemes: [String]
    public var mixpanelToken: String?

    public init(
        enableRuntimeMonitoring: Bool = true,
        monitoringInterval: TimeInterval = 15,
        failClosedOnPinningError: Bool = true,
        expectedTeamIdentifier: String? = nil,
        expectedBundleIdentifier: String? = nil,
        expectedExecutableSHA256: String? = nil,
        encryptedConfiguration: Data? = nil,
        checkNetworkSecurity: Bool = true,
        checkScreenCapture: Bool = true,
        monitoredAppSchemes: [String] = RemoteApps.allCases.map(\.rawValue),
        mixpanelToken: String? = nil
    ) {
        self.enableRuntimeMonitoring = enableRuntimeMonitoring
        self.monitoringInterval = max(2, monitoringInterval)
        self.failClosedOnPinningError = failClosedOnPinningError
        self.expectedTeamIdentifier = expectedTeamIdentifier
        self.expectedBundleIdentifier = expectedBundleIdentifier
        self.expectedExecutableSHA256 = expectedExecutableSHA256
        self.encryptedConfiguration = encryptedConfiguration
        self.checkNetworkSecurity = checkNetworkSecurity
        self.checkScreenCapture = checkScreenCapture
        self.monitoredAppSchemes = monitoredAppSchemes
        self.mixpanelToken = mixpanelToken
    }

    // Compatibility initializer to resolve Undefined Symbol errors
    public init(
        enableRuntimeMonitoring: Bool = true,
        monitoringInterval: TimeInterval = 15,
        failClosedOnPinningError: Bool = true,
        expectedTeamIdentifier: String? = nil,
        expectedBundleIdentifier: String? = nil,
        expectedExecutableSHA256: String? = nil,
        encryptedConfiguration: Data? = nil
    ) {
        self.init(
            enableRuntimeMonitoring: enableRuntimeMonitoring,
            monitoringInterval: monitoringInterval,
            failClosedOnPinningError: failClosedOnPinningError,
            expectedTeamIdentifier: expectedTeamIdentifier,
            expectedBundleIdentifier: expectedBundleIdentifier,
            expectedExecutableSHA256: expectedExecutableSHA256,
            encryptedConfiguration: encryptedConfiguration,
            checkNetworkSecurity: true,
            checkScreenCapture: true,
            monitoredAppSchemes: RemoteApps.allCases.map(\.rawValue),
            mixpanelToken: nil
        )
    }

    public static let production = SecureShieldConfiguration()
}

public enum SecureShieldError: Error, Sendable, Equatable {
    case sslPinningNotConfigured
    case invalidCertificateData
    case integrityCheckUnavailable
}
