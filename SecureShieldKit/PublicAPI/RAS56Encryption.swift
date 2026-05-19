import Foundation
import Security

/// A public utility for performing secure RSA encryption, decryption, signing, and signature verification with SHA-256 (RSA-256).
/// It provides methods to generate key pairs, import/export keys, and execute cryptographic operations,
/// designed to be called easily from outside the SDK.
public final class RAS56Encryption: Sendable {
    
    /// Standard error definitions for RAS56 Encryption.
    public enum EncryptionError: LocalizedError {
        case keyGenerationFailed
        case invalidKeyFormat
        case encryptionFailed(String)
        case decryptionFailed(String)
        case signingFailed(String)
        case verificationFailed
        
        public var errorDescription: String? {
            switch self {
            case .keyGenerationFailed:
                return "Failed to generate RSA-256 cryptographic key pair."
            case .invalidKeyFormat:
                return "The provided cryptographic key data or format is invalid."
            case .encryptionFailed(let message):
                return "Encryption operation failed: \(message)"
            case .decryptionFailed(let message):
                return "Decryption operation failed: \(message)"
            case .signingFailed(let message):
                return "Signing operation failed: \(message)"
            case .verificationFailed:
                return "Signature verification failed."
            }
        }
    }
    
    /// Generates a new RSA public-private key pair with the specified bit size (default: 2048-bit for optimal performance and strong security).
    ///
    /// - Parameter keySize: The bit length of the key. Recommended 2048 or 4096.
    /// - Returns: A tuple containing the public and private `SecKey` objects.
    public static func generateKeyPair(keySize: Int = 2048) throws -> (publicKey: SecKey, privateKey: SecKey) {
        let attributes: [CFString: Any] = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits: keySize
        ]
        
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            let errorMsg = error?.takeRetainedValue().localizedDescription ?? "Unknown error"
            throw EncryptionError.encryptionFailed("Key generation failed: \(errorMsg)")
        }
        
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw EncryptionError.keyGenerationFailed
        }
        
        return (publicKey, privateKey)
    }
    
    // MARK: - Core SecKey Operations
    
    /// Encrypts data using a public `SecKey` with RSA OAEP and SHA-256.
    public static func encrypt(data: Data, publicKey: SecKey) throws -> Data {
        let algorithm = SecKeyAlgorithm.rsaEncryptionOAEPSHA256
        
        guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, algorithm) else {
            throw EncryptionError.encryptionFailed("Algorithm not supported on this public key.")
        }
        
        var error: Unmanaged<CFError>?
        guard let encryptedData = SecKeyCreateEncryptedData(publicKey, algorithm, data as CFData, &error) else {
            let errorMsg = error?.takeRetainedValue().localizedDescription ?? "Unknown error"
            throw EncryptionError.encryptionFailed(errorMsg)
        }
        
        return encryptedData as Data
    }
    
    /// Decrypts data using a private `SecKey` with RSA OAEP and SHA-256.
    public static func decrypt(data: Data, privateKey: SecKey) throws -> Data {
        let algorithm = SecKeyAlgorithm.rsaEncryptionOAEPSHA256
        
        guard SecKeyIsAlgorithmSupported(privateKey, .decrypt, algorithm) else {
            throw EncryptionError.decryptionFailed("Algorithm not supported on this private key.")
        }
        
        var error: Unmanaged<CFError>?
        guard let decryptedData = SecKeyCreateDecryptedData(privateKey, algorithm, data as CFData, &error) else {
            let errorMsg = error?.takeRetainedValue().localizedDescription ?? "Unknown error"
            throw EncryptionError.decryptionFailed(errorMsg)
        }
        
        return decryptedData as Data
    }
    
    /// Signs data using a private `SecKey` and SHA-256 PKCS1v1.5.
    public static func sign(data: Data, privateKey: SecKey) throws -> Data {
        let algorithm = SecKeyAlgorithm.rsaSignatureMessagePKCS1v15SHA256
        
        guard SecKeyIsAlgorithmSupported(privateKey, .sign, algorithm) else {
            throw EncryptionError.signingFailed("Algorithm not supported on this private key.")
        }
        
        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(privateKey, algorithm, data as CFData, &error) else {
            let errorMsg = error?.takeRetainedValue().localizedDescription ?? "Unknown error"
            throw EncryptionError.signingFailed(errorMsg)
        }
        
        return signature as Data
    }
    
    /// Verifies a signature against data using a public `SecKey` and SHA-256 PKCS1v1.5.
    public static func verify(data: Data, signature: Data, publicKey: SecKey) -> Bool {
        let algorithm = SecKeyAlgorithm.rsaSignatureMessagePKCS1v15SHA256
        
        guard SecKeyIsAlgorithmSupported(publicKey, .verify, algorithm) else {
            return false
        }
        
        var error: Unmanaged<CFError>?
        let result = SecKeyVerifySignature(publicKey, algorithm, data as CFData, signature as CFData, &error)
        return result
    }
    
    // MARK: - Base64 Key Helpers for External SDK Method Calls
    
    /// Imports a public key from its raw DER binary representation.
    public static func importPublicKey(from derData: Data) throws -> SecKey {
        let attributes: [CFString: Any] = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass: kSecAttrKeyClassPublic
        ]
        
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(derData as CFData, attributes as CFDictionary, &error) else {
            throw EncryptionError.invalidKeyFormat
        }
        return key
    }
    
    /// Imports a private key from its raw DER binary representation.
    public static func importPrivateKey(from derData: Data) throws -> SecKey {
        let attributes: [CFString: Any] = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass: kSecAttrKeyClassPrivate
        ]
        
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(derData as CFData, attributes as CFDictionary, &error) else {
            throw EncryptionError.invalidKeyFormat
        }
        return key
    }
    
    /// Exports a `SecKey` to raw DER data format.
    public static func exportKeyData(_ key: SecKey) throws -> Data {
        var error: Unmanaged<CFError>?
        guard let externalRepresentation = SecKeyCopyExternalRepresentation(key, &error) else {
            let errorMsg = error?.takeRetainedValue().localizedDescription ?? "Unknown error"
            throw EncryptionError.invalidKeyFormat
        }
        return externalRepresentation as Data
    }
    
    /// Encrypts data using a public key string encoded in Base64 (perfect for external method calls).
    public static func encrypt(data: Data, publicKeyBase64: String) throws -> Data {
        guard let derData = Data(base64Encoded: publicKeyBase64) else {
            throw EncryptionError.invalidKeyFormat
        }
        let publicKey = try importPublicKey(from: derData)
        return try encrypt(data: data, publicKey: publicKey)
    }
    
    /// Decrypts data using a private key string encoded in Base64 (perfect for external method calls).
    public static func decrypt(data: Data, privateKeyBase64: String) throws -> Data {
        guard let derData = Data(base64Encoded: privateKeyBase64) else {
            throw EncryptionError.invalidKeyFormat
        }
        let privateKey = try importPrivateKey(from: derData)
        return try decrypt(data: data, privateKey: privateKey)
    }
    
    /// Signs data using a private key string encoded in Base64.
    public static func sign(data: Data, privateKeyBase64: String) throws -> Data {
        guard let derData = Data(base64Encoded: privateKeyBase64) else {
            throw EncryptionError.invalidKeyFormat
        }
        let privateKey = try importPrivateKey(from: derData)
        return try sign(data: data, privateKey: privateKey)
    }
    
    /// Verifies a signature against data using a public key string encoded in Base64.
    public static func verify(data: Data, signature: Data, publicKeyBase64: String) -> Bool {
        do {
            guard let derData = Data(base64Encoded: publicKeyBase64) else {
                return false
            }
            let publicKey = try importPublicKey(from: derData)
            return verify(data: data, signature: signature, publicKey: publicKey)
        } catch {
            return false
        }
    }
}
