import Foundation

public struct SimulatorDetector: SimulatorDetecting {
    public init() {}

    public func isSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
}
