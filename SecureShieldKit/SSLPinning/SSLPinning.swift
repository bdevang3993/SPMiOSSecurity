import CryptoKit
import Foundation
import Security

public final class SSLPinning: NSObject, URLSessionDelegate, @unchecked Sendable {
    public static let shared = SSLPinning()

    private let lock = NSLock()
    private var pinnedCertificateHashes: Set<String> = []
    private var pinnedPublicKeyHashes: Set<String> = []
    private var failClosed = true

    public func configure(
        certificates: [Data],
        publicKeys: [Data],
        failClosed: Bool = true
    ) {
        lock.withLock {
            pinnedCertificateHashes = Set(certificates.map(Crypto.sha256Hex))
            pinnedPublicKeyHashes = Set(publicKeys.map(Crypto.sha256Hex))
            self.failClosed = failClosed
        }
    }

    public func makeURLSession(configuration: URLSessionConfiguration = .ephemeral) -> URLSession {
        URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }

    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        if validate(serverTrust: trust) {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            ThreatCenter.shared.report(SecurityThreat(
                type: .sslPinningFailure,
                level: .critical,
                metadata: ["host": challenge.protectionSpace.host]
            ))
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    public func validate(serverTrust: SecTrust) -> Bool {
        let pins = lock.withLock {
            (pinnedCertificateHashes, pinnedPublicKeyHashes, failClosed)
        }

        guard !pins.0.isEmpty || !pins.1.isEmpty else {
            return !pins.2
        }

        guard SecTrustEvaluateWithError(serverTrust, nil) else {
            return false
        }

        let certificates = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate] ?? []
        for certificate in certificates {
            let certificateData = SecCertificateCopyData(certificate) as Data
            if pins.0.contains(Crypto.sha256Hex(certificateData)) {
                return true
            }

            if let key = SecCertificateCopyKey(certificate),
               let keyData = SecKeyCopyExternalRepresentation(key, nil) as Data? {
                if pins.1.contains(Crypto.sha256Hex(keyData)) {
                    return true
                }
            }
        }

        return false
    }
}

public struct PinnedNetworkingClient: Sendable {
    private let session: URLSession
    public let bearerToken: String

    public init(session: URLSession = SSLPinning.shared.makeURLSession(), bearerToken: String = "") {
        self.session = session
        self.bearerToken = bearerToken
    }

    public func data(from url: URL) async throws -> (Data, URLResponse) {
        try await session.data(from: url)
    }

    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }

    public func fetchGeneric<T: Decodable>(urlString: String) async throws -> T {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.allHTTPHeaderFields = [
            "accept": "application/json",
            "Authorization": "Bearer \(bearerToken)"
        ]
        
        let (data, _) = try await self.data(for: request)
        return try JSONDecoder().decode(T.self, from: data)
    }
}
