import Foundation

public final class ReverseEngineeringDetector: ReverseEngineeringDetecting {
    public let threatType: ThreatType = .reverseEngineering

    private let suspiciousImages = [
        "cycript", "frida", "objection", "class-dump", "dumpdecrypted",
        "flex", "revealserver"
    ]

    private let suspiciousProcessNames = ["Hopper", "IDA", "lldb", "debugserver", "frida-server"]

    public init() {}

    public func isReverseEngineeringEnvironmentDetected() -> Bool {
        !evaluate().isEmpty
    }

    public func scan() async -> [SecurityThreat] {
        evaluate().map {
            SecurityThreat(type: .reverseEngineering, level: $0.level, metadata: $0.metadata)
        }
    }

    private func evaluate() -> [DetectionFinding] {
        var findings: [DetectionFinding] = []

        for image in DyldImageScanner.containsAny(suspiciousImages) {
            findings.append(.init(level: .critical, metadata: ["indicator": "reverse_engineering_image", "image": image]))
        }

        for process in suspiciousProcessNames where processListContains(process) {
            findings.append(.init(level: .high, metadata: ["indicator": "suspicious_process", "process": process]))
        }

        if hasReadableObjectiveCMetadata() {
            findings.append(.init(level: .low, metadata: ["indicator": "objc_metadata_exposed"]))
        }

        return findings
    }

    private func processListContains(_ name: String) -> Bool {
        #if os(macOS)
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-axo", "comm"]
        process.standardOutput = pipe
        try? process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.lowercased() ?? ""
        return output.contains(name.lowercased())
        #else
        return false
        #endif
    }

    private func hasReadableObjectiveCMetadata() -> Bool {
        ProcessInfo.processInfo.environment["OBJC_PRINT_CLASS_SETUP"] != nil
    }
}
