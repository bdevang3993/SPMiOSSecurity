import Foundation
import ObjectiveC.runtime

public final class RuntimeHookDetector: RuntimeHookDetecting {
    public let threatType: ThreatType = .runtimeHook

    private let suspiciousImages = [
        "frida", "fridagadget", "gum-js-loop", "re.frida.server",
        "fishhook", "mobilesubstrate", "substrate", "substitute",
        "libhooker", "cycript", "ssl-kill-switch", "shadow"
    ]

    public init() {}

    public func isRuntimeHooked() -> Bool {
        !evaluate().isEmpty
    }

    public func scan() async -> [SecurityThreat] {
        evaluate().map {
            SecurityThreat(type: $0.type, level: $0.level, metadata: $0.metadata)
        }
    }

    private func evaluate() -> [(type: ThreatType, level: ThreatLevel, metadata: [String: String])] {
        var findings: [(ThreatType, ThreatLevel, [String: String])] = []

        for image in DyldImageScanner.containsAny(suspiciousImages) {
            let type: ThreatType = image.contains("frida") ? .frida : .runtimeHook
            findings.append((type, .critical, ["indicator": "dyld_image", "image": image]))
        }

        if isObjCMessageForwardingSuspicious() {
            findings.append((.runtimeHook, .medium, ["indicator": "objc_forwarding"]))
        }

        if hasSuspiciousEnvironment() {
            findings.append((.frida, .high, ["indicator": "environment"]))
        }

        return findings
    }

    private func isObjCMessageForwardingSuspicious() -> Bool {
        guard let method = class_getInstanceMethod(NSObject.self, #selector(NSObject.description)) else {
            return false
        }
        let implementation = method_getImplementation(method)
        let symbol = String(describing: implementation).lowercased()
        return symbol.contains("frida") || symbol.contains("substrate")
    }

    private func hasSuspiciousEnvironment() -> Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment.keys.contains { key in
            key.lowercased().contains("frida") || key.lowercased().contains("cycript")
        }
    }
}
