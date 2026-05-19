import CryptoKit
#if canImport(DeviceCheck)
import DeviceCheck
#endif
import Foundation

public struct DeviceTrustService: Sendable {
    public init() {}

    public func isDeviceCheckSupported() -> Bool {
        #if canImport(DeviceCheck)
        return DCDevice.current.isSupported
        #else
        return false
        #endif
    }

    public func deviceCheckToken() async throws -> Data {
        #if canImport(DeviceCheck)
        return try await DCDevice.current.generateToken()
        #else
        throw SecureShieldError.integrityCheckUnavailable
        #endif
    }

    public func isAppAttestSupported() -> Bool {
        #if canImport(DeviceCheck)
        if #available(iOS 14.0, *) {
            return DCAppAttestService.shared.isSupported
        }
        return false
        #else
        return false
        #endif
    }

    public func generateAppAttestKey() async throws -> String {
        #if canImport(DeviceCheck)
        guard #available(iOS 14.0, *) else { throw SecureShieldError.integrityCheckUnavailable }
        return try await DCAppAttestService.shared.generateKey()
        #else
        throw SecureShieldError.integrityCheckUnavailable
        #endif
    }

    public func attestAppKey(_ keyIdentifier: String, clientDataHash: Data) async throws -> Data {
        #if canImport(DeviceCheck)
        guard #available(iOS 14.0, *) else { throw SecureShieldError.integrityCheckUnavailable }
        return try await DCAppAttestService.shared.attestKey(keyIdentifier, clientDataHash: clientDataHash)
        #else
        throw SecureShieldError.integrityCheckUnavailable
        #endif
    }
}

public enum SecureEnclaveSupport {
    public static func isAvailable() -> Bool {
        SecureEnclave.isAvailable
    }

    public static func makeSigningKey() throws -> SecureEnclave.P256.Signing.PrivateKey {
        try SecureEnclave.P256.Signing.PrivateKey()
    }

    public static func sign(_ digest: SHA256.Digest, using key: SecureEnclave.P256.Signing.PrivateKey) throws -> P256.Signing.ECDSASignature {
        try key.signature(for: digest)
    }
}
