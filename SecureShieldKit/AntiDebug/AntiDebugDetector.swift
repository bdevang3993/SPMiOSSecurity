import Darwin
import Foundation

public class AntiDebugDetector: DebuggerDetecting {
    public let threatType: ThreatType = .debugger

    public init() {}

    public func denyDebuggerAttach() {
        #if os(iOS) && !targetEnvironment(simulator)
        _ = secure_ptrace(31, 0, nil, 0)
        #endif
    }

    public func isDebuggerAttached() -> Bool {
        isSysctlDebugged() || hasDebuggerEnvironment() || timingCheckIndicatesTracing()
    }

    public func scan() async -> [SecurityThreat] {
        isDebuggerAttached()
            ? [SecurityThreat(type: .debugger, level: .critical, metadata: ["indicator": "debugger_attached"])]
            : []
    }

    private func isSysctlDebugged() -> Bool {
        #if os(iOS) || os(macOS)
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var name: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        let nameCount = u_int(name.count)

        let result = name.withUnsafeMutableBufferPointer { pointer -> Int32 in
            sysctl(pointer.baseAddress, nameCount, &info, &size, nil, 0)
        }

        guard result == 0 else { return false }
        return (info.kp_proc.p_flag & P_TRACED) != 0
        #else
        return false
        #endif
    }

    private func hasDebuggerEnvironment() -> Bool {
        let environment = ProcessInfo.processInfo.environment
        let suspiciousKeys = ["LLDB", "DYLD_INSERT_LIBRARIES", "NSUnbufferedIO"]
        return suspiciousKeys.contains { environment[$0] != nil }
    }

    private func timingCheckIndicatesTracing() -> Bool {
        let start = DispatchTime.now().uptimeNanoseconds
        for _ in 0..<10_000 { _ = UUID().uuidString.hashValue }
        let elapsed = DispatchTime.now().uptimeNanoseconds - start
        return elapsed > 80_000_000
    }
}

#if os(iOS) && !targetEnvironment(simulator)
@_silgen_name("ptrace")
private func secure_ptrace(
    _ request: Int32,
    _ pid: pid_t,
    _ addr: UnsafeMutableRawPointer?,
    _ data: Int32
) -> Int32
#endif
