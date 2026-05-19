import CryptoKit
import Foundation

public struct EncryptedConfiguration: Sendable {
    public let sealedBoxData: Data

    public init(sealedBoxData: Data) {
        self.sealedBoxData = sealedBoxData
    }

    public static func seal(_ data: Data, using key: SymmetricKey) throws -> EncryptedConfiguration {
        let box = try AES.GCM.seal(data, using: key)
        guard let combined = box.combined else {
            throw SecureShieldError.integrityCheckUnavailable
        }
        return EncryptedConfiguration(sealedBoxData: combined)
    }

    public func open(using key: SymmetricKey) throws -> Data {
        let box = try AES.GCM.SealedBox(combined: sealedBoxData)
        return try AES.GCM.open(box, using: key)
    }
}
