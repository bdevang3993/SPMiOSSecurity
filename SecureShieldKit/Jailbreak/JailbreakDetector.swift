import Darwin
import Foundation

public final class JailbreakDetector: JailbreakDetecting {
    public let threatType: ThreatType = .jailbreak

    private let suspiciousPaths = [
        "/Applications/Cydia.app",
        "/Applications/Sileo.app",
        "/Applications/Zebra.app",
        "/Library/MobileSubstrate/MobileSubstrate.dylib",
        "/usr/lib/libsubstitute.dylib",
        "/usr/lib/substrate",
        "/bin/bash",
        "/usr/sbin/sshd",
        "/etc/apt",
        "/private/var/lib/apt",
        "/private/var/stash"
    ]

    private let suspiciousURLSchemes = ["cydia://", "sileo://", "zbra://", "undecimus://", "filza://"]
    private let writableSystemPaths = ["/private", "/root", "/var/mobile/Library"]
    private let suspiciousDylibs = ["mobilesubstrate", "substitute", "substrate", "libhooker"]

    public init() {}

    public static func isJailbroken() -> Bool {
        JailbreakDetector().isJailbroken()
    }

    public func isJailbroken() -> Bool {
        !evaluate().isEmpty
    }

    public func scan() async -> [SecurityThreat] {
        evaluate().map {
            SecurityThreat(type: .jailbreak, level: $0.level, metadata: $0.metadata)
        }
    }

    private func evaluate() -> [DetectionFinding] {
        var findings: [DetectionFinding] = []

        for path in suspiciousPaths where FileManager.default.fileExists(atPath: path) {
            findings.append(.init(level: .critical, metadata: ["indicator": "file_exists", "path": path]))
        }

        for path in writableSystemPaths where canWrite(toDirectory: path) {
            findings.append(.init(level: .high, metadata: ["indicator": "system_path_writable", "path": path]))
        }

        if hasSandboxEscape() {
            findings.append(.init(level: .critical, metadata: ["indicator": "sandbox_escape"]))
        }

        for link in symbolicLinkFindings() {
            findings.append(.init(level: .high, metadata: ["indicator": "symbolic_link", "path": link]))
        }

        if canForkProcess() {
            findings.append(.init(level: .high, metadata: ["indicator": "fork_allowed"]))
        }

        for dylib in DyldImageScanner.containsAny(suspiciousDylibs) {
            findings.append(.init(level: .critical, metadata: ["indicator": "suspicious_dylib", "image": dylib]))
        }

        for scheme in suspiciousURLSchemes where canOpenURLScheme(scheme) {
            findings.append(.init(level: .medium, metadata: ["indicator": "url_scheme", "scheme": scheme]))
        }

        return findings
    }

    private func canWrite(toDirectory directory: String) -> Bool {
        let filename = ".secureshield-\(UUID().uuidString)"
        let url = URL(fileURLWithPath: directory).appendingPathComponent(filename)
        do {
            try Data([0x53]).write(to: url, options: .atomic)
            try? FileManager.default.removeItem(at: url)
            return true
        } catch {
            return false
        }
    }

    private func hasSandboxEscape() -> Bool {
        let restricted = "/private/var/mobile/Library/Preferences"
        return FileManager.default.isReadableFile(atPath: restricted)
    }

    private func symbolicLinkFindings() -> [String] {
        ["/Applications", "/Library/Ringtones", "/Library/Wallpaper", "/usr/include"].filter { path in
            guard let attributes = try? FileManager.default.attributesOfItem(atPath: path),
                  let type = attributes[.type] as? FileAttributeType else {
                return false
            }
            return type == .typeSymbolicLink
        }
    }

    private func canForkProcess() -> Bool {
        #if os(iOS) && !targetEnvironment(simulator)
        typealias ForkFunction = @convention(c) () -> pid_t
        guard let symbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "fork") else {
            return false
        }
        let forkFunction = unsafeBitCast(symbol, to: ForkFunction.self)
        let pid = forkFunction()
        if pid >= 0 {
            if pid == 0 { _exit(0) }
            var status: Int32 = 0
            _ = waitpid(pid, &status, 0)
            return true
        }
        return false
        #else
        return false
        #endif
    }

    private func canOpenURLScheme(_ scheme: String) -> Bool {
        #if canImport(UIKit)
        guard let url = URL(string: scheme) else { return false }
        return UIApplicationBridge.canOpenURL(url)
        #else
        return false
        #endif
    }
}

struct DetectionFinding {
    let level: ThreatLevel
    let metadata: [String: String]
}
