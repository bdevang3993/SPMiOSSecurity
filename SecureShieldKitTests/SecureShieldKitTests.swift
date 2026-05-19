//
//  SecureShieldKitTests.swift
//  SecureShieldKitTests
//
//  Created by Apple on 08/05/26.
//

import XCTest
@testable import SecureShieldKit

final class SecureShieldKitTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPinnedNetworkingClientFetchGeneric() async throws {
        let client = PinnedNetworkingClient(bearerToken: "test_token")
        XCTAssertEqual(client.bearerToken, "test_token")
        
        do {
            let _: String = try await client.fetchGeneric(urlString: "invalid_url")
            XCTFail("Should have thrown unsupportedURL error")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .unsupportedURL)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testTMDBServiceGenericCalls() async throws {
        let service = TMDBService()
        
        // Define a mock decodable model inside the test to simulate the client application passing a model from the outside.
        struct MockMovieResponse: Decodable {
            let page: Int?
        }
        
        do {
            // Testing fetchGeneric with custom baseURL, endpoint, httpMethod, headers, timeInterval, and bearerToken parameters passed in the method call
            let _: MockMovieResponse = try await service.fetchGeneric(
                baseURL: "invalid_url",
                endpoint: "endpoint",
                httpMethod: "GET",
                headers: ["Custom-Header": "TestValue"],
                timeInterval: 15.0,
                bearerToken: "custom_bearer_token"
            )
            XCTFail("Should have thrown unsupportedURL error")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .unsupportedURL)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRAS56EncryptionSecKeyRoundTrip() throws {
        // 1. Generate key pair
        let (publicKey, privateKey) = try RAS56Encryption.generateKeyPair(keySize: 2048)
        
        // 2. Encryption and Decryption Round-Trip
        let originalMessage = "Hello from outside of SecureShieldKit SDK!"
        let originalData = try XCTUnwrap(originalMessage.data(using: .utf8))
        
        let encryptedData = try RAS56Encryption.encrypt(data: originalData, publicKey: publicKey)
        XCTAssertNotEqual(originalData, encryptedData)
        
        let decryptedData = try RAS56Encryption.decrypt(data: encryptedData, privateKey: privateKey)
        let decryptedMessage = String(data: decryptedData, encoding: .utf8)
        XCTAssertEqual(originalMessage, decryptedMessage)
        
        // 3. Signing and Verification Round-Trip
        let signature = try RAS56Encryption.sign(data: originalData, privateKey: privateKey)
        let isVerified = RAS56Encryption.verify(data: originalData, signature: signature, publicKey: publicKey)
        XCTAssertTrue(isVerified)
        
        // Verify invalid signature fails
        let badSignature = signature + Data([0x00])
        let isBadVerified = RAS56Encryption.verify(data: originalData, signature: badSignature, publicKey: publicKey)
        XCTAssertFalse(isBadVerified)
    }
    
    func testRAS56EncryptionBase64KeysRoundTrip() throws {
        // 1. Generate key pair
        let (publicKey, privateKey) = try RAS56Encryption.generateKeyPair(keySize: 2048)
        
        // 2. Export keys to Base64 format (simulating storage/external transmission)
        let publicKeyDER = try RAS56Encryption.exportKeyData(publicKey)
        let privateKeyDER = try RAS56Encryption.exportKeyData(privateKey)
        
        let publicKeyBase64 = publicKeyDER.base64EncodedString()
        let privateKeyBase64 = privateKeyDER.base64EncodedString()
        
        XCTAssertFalse(publicKeyBase64.isEmpty)
        XCTAssertFalse(privateKeyBase64.isEmpty)
        
        // 3. Perform cryptographic operations from outside SDK using Base64 strings
        let originalMessage = "Securing transmission using portable Base64 key string formats."
        let originalData = try XCTUnwrap(originalMessage.data(using: .utf8))
        
        // Encryption
        let encryptedData = try RAS56Encryption.encrypt(data: originalData, publicKeyBase64: publicKeyBase64)
        XCTAssertNotEqual(originalData, encryptedData)
        
        // Decryption
        let decryptedData = try RAS56Encryption.decrypt(data: encryptedData, privateKeyBase64: privateKeyBase64)
        let decryptedMessage = String(data: decryptedData, encoding: .utf8)
        XCTAssertEqual(originalMessage, decryptedMessage)
        
        // Signing
        let signature = try RAS56Encryption.sign(data: originalData, privateKeyBase64: privateKeyBase64)
        
        // Verification
        let isVerified = RAS56Encryption.verify(data: originalData, signature: signature, publicKeyBase64: publicKeyBase64)
        XCTAssertTrue(isVerified)
        
        // Verify invalid base64 key imports throw errors
        XCTAssertThrowsError(try RAS56Encryption.encrypt(data: originalData, publicKeyBase64: "invalid_base64_string"))
        XCTAssertThrowsError(try RAS56Encryption.decrypt(data: encryptedData, privateKeyBase64: "invalid_base64_string"))
    }

    func testAESEncryptionDataRoundTrip() throws {
        // 1. Generate Key
        let key = AESEncryption.generateKey()
        
        // 2. Encryption and Decryption Round-Trip
        let originalMessage = "Secret API Payload"
        let originalData = try XCTUnwrap(originalMessage.data(using: .utf8))
        
        let encryptedData = try AESEncryption.encrypt(data: originalData, key: key)
        XCTAssertNotEqual(originalData, encryptedData)
        
        let decryptedData = try AESEncryption.decrypt(combinedData: encryptedData, key: key)
        let decryptedMessage = String(data: decryptedData, encoding: .utf8)
        XCTAssertEqual(originalMessage, decryptedMessage)
        
        // 3. Verify that decrypting with a different key throws an error
        let wrongKey = AESEncryption.generateKey()
        XCTAssertThrowsError(try AESEncryption.decrypt(combinedData: encryptedData, key: wrongKey))
    }
    
    func testAESEncryptionBase64RoundTrip() throws {
        // 1. Generate Key Base64
        let keyBase64 = AESEncryption.generateKeyBase64()
        XCTAssertFalse(keyBase64.isEmpty)
        
        // 2. Base64 Portable Encryption/Decryption Round-Trip
        let originalMessage = "Super Secret Base64 Message!"
        
        let encryptedBase64 = try AESEncryption.encrypt(string: originalMessage, keyBase64: keyBase64)
        XCTAssertNotEqual(originalMessage, encryptedBase64)
        
        let decryptedMessage = try AESEncryption.decrypt(base64String: encryptedBase64, keyBase64: keyBase64)
        XCTAssertEqual(originalMessage, decryptedMessage)
        
        // 3. Verify handling of incorrect key formats
        let badKeyBase64 = "shortKey"
        XCTAssertThrowsError(try AESEncryption.encrypt(string: originalMessage, keyBase64: badKeyBase64))
        
        // 4. Verify decryption with a wrong but valid length key throws an error
        let otherKeyBase64 = AESEncryption.generateKeyBase64()
        XCTAssertThrowsError(try AESEncryption.decrypt(base64String: encryptedBase64, keyBase64: otherKeyBase64))
        
        // 5. Verify malformed ciphertext throws an error
        XCTAssertThrowsError(try AESEncryption.decrypt(base64String: "invalid_ciphertext", keyBase64: keyBase64))
    }

}

