import Foundation
import Security

public final class IntegrityVerifier: IntegrityVerifying {
    public let threatType: ThreatType = .integrityViolation

    private let configuration: SecureShieldConfiguration

    public init(configuration: SecureShieldConfiguration = .production) {
        self.configuration = configuration
    }

    public func verifyIntegrity() -> Bool {
        evaluate().isEmpty
    }

    public func scan() async -> [SecurityThreat] {
        evaluate().map {
            SecurityThreat(type: .integrityViolation, level: $0.level, metadata: $0.metadata)
        }
    }

    private func evaluate() -> [DetectionFinding] {
        var findings: [DetectionFinding] = []

        if let expectedBundleIdentifier = configuration.expectedBundleIdentifier,
           Bundle.main.bundleIdentifier != expectedBundleIdentifier {
            findings.append(.init(level: .critical, metadata: [
                "indicator": "bundle_identifier_mismatch",
                "expected": expectedBundleIdentifier,
                "actual": Bundle.main.bundleIdentifier ?? "unknown"
            ]))
        }

        if let expectedHash = configuration.expectedExecutableSHA256,
           let actualHash = executableSHA256(),
           !Crypto.constantTimeEquals(actualHash.lowercased(), expectedHash.lowercased()) {
            findings.append(.init(level: .critical, metadata: [
                "indicator": "executable_checksum_mismatch",
                "expected": expectedHash,
                "actual": actualHash
            ]))
        }

        if let expectedTeamIdentifier = configuration.expectedTeamIdentifier,
           let actualTeamIdentifier = embeddedTeamIdentifier(),
           actualTeamIdentifier != expectedTeamIdentifier {
            findings.append(.init(level: .critical, metadata: [
                "indicator": "team_identifier_mismatch",
                "expected": expectedTeamIdentifier,
                "actual": actualTeamIdentifier
            ]))
        }

        if isReceiptMissingOnDevice() {
            findings.append(.init(level: .medium, metadata: ["indicator": "app_store_receipt_missing"]))
        }

        return findings
    }

    private func executableSHA256() -> String? {
        guard let executableURL = Bundle.main.executableURL,
              let data = try? Data(contentsOf: executableURL, options: .mappedIfSafe) else {
            return nil
        }
        return Crypto.sha256Hex(data)
    }

    private func embeddedTeamIdentifier() -> String? {
        guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
              let data = try? Data(contentsOf: url),
              let text = String(data: data, encoding: .isoLatin1) else {
            return nil
        }

        let pattern = "<key>com.apple.developer.team-identifier</key>\\s*<string>([^<]+)</string>"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[range])
    }

    private func isReceiptMissingOnDevice() -> Bool {
        #if os(iOS) && !targetEnvironment(simulator)
        return Bundle.main.appStoreReceiptURL.map { !FileManager.default.fileExists(atPath: $0.path) } ?? false
        #else
        return false
        #endif
    }
}
