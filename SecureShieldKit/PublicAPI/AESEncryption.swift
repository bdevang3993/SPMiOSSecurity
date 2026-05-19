import Foundation
import CryptoKit

/// A public utility for performing secure AES encryption and decryption using modern CryptoKit (AES-GCM 256-bit).
/// It provides methods to generate keys, and perform encryption/decryption on both raw Data and Base64-encoded strings.
public final class AESEncryption: Sendable {
    
    /// Standard error definitions for AES Encryption.
    public enum EncryptionError: LocalizedError {
        case invalidKeyFormat
        case encryptionFailed(String)
        case decryptionFailed(String)
        case invalidCiphertext
        
        public var errorDescription: String? {
            switch self {
            case .invalidKeyFormat:
                return "The provided cryptographic key data or format is invalid (must be 256-bit / 32-byte key)."
            case .encryptionFailed(let message):
                return "AES Encryption operation failed: \(message)"
            case .decryptionFailed(let message):
                return "AES Decryption operation failed: \(message)"
            case .invalidCiphertext:
                return "The provided ciphertext or combined sealed box format is invalid."
            }
        }
    }
    
    /// Generates a new 256-bit AES symmetric key.
    public static func generateKey() -> SymmetricKey {
        return SymmetricKey(size: .bits256)
    }
    
    /// Generates a new 256-bit AES symmetric key and returns its Base64 representation.
    public static func generateKeyBase64() -> String {
        let key = generateKey()
        return key.withUnsafeBytes { Data($0).base64EncodedString() }
    }
    
    // MARK: - Core CryptoKit Operations
    
    /// Encrypts raw data using AES-GCM with a 256-bit symmetric key.
    ///
    /// - Parameters:
    ///   - data: The raw input data to encrypt.
    ///   - key: The `SymmetricKey` to use.
    /// - Returns: A combined `Data` representation containing the nonce, ciphertext, and tag.
    public static func encrypt(data: Data, key: SymmetricKey) throws -> Data {
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            guard let combined = sealedBox.combined else {
                throw EncryptionError.encryptionFailed("Unable to create combined sealed box representation.")
            }
            return combined
        } catch {
            throw EncryptionError.encryptionFailed(error.localizedDescription)
        }
    }
    
    /// Decrypts combined sealed box data using AES-GCM with a 256-bit symmetric key.
    ///
    /// - Parameters:
    ///   - combinedData: A combined `Data` representation (nonce + ciphertext + tag).
    ///   - key: The `SymmetricKey` to use.
    /// - Returns: The decrypted raw data.
    public static func decrypt(combinedData: Data, key: SymmetricKey) throws -> Data {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: combinedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return decryptedData
        } catch {
            throw EncryptionError.decryptionFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Base64 Portability Helpers
    
    /// Helper to convert a Base64-encoded key string into a CryptoKit `SymmetricKey`.
    public static func importKey(from keyBase64: String) throws -> SymmetricKey {
        guard let keyData = Data(base64Encoded: keyBase64), keyData.count == 32 else {
            throw EncryptionError.invalidKeyFormat
        }
        return SymmetricKey(data: keyData)
    }
    
    /// Encrypts a plaintext string using a Base64-encoded key string, returning a Base64-encoded combined sealed box.
    public static func encrypt(string: String, keyBase64: String) throws -> String {
        guard let data = string.data(using: .utf8) else {
            throw EncryptionError.encryptionFailed("Failed to encode input string to UTF-8.")
        }
        let key = try importKey(from: keyBase64)
        let encryptedData = try encrypt(data: data, key: key)
        return encryptedData.base64EncodedString()
    }
    
    /// Decrypts a Base64-encoded combined sealed box using a Base64-encoded key string, returning the plaintext string.
    public static func decrypt(base64String: String, keyBase64: String) throws -> String {
        guard let combinedData = Data(base64Encoded: base64String) else {
            throw EncryptionError.invalidCiphertext
        }
        let key = try importKey(from: keyBase64)
        let decryptedData = try decrypt(combinedData: combinedData, key: key)
        guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.decryptionFailed("Failed to decode decrypted data to UTF-8.")
        }
        return decryptedString
    }
}
