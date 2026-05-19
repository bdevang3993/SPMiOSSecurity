import Foundation

public final class RuntimeProtector: @unchecked Sendable {
    public static let shared = RuntimeProtector()

    private let lock = NSLock()
    private var protectedSelectors: Set<String> = []

    public func protect(selector: Selector, on type: AnyClass) {
        let key = "\(NSStringFromClass(type))#\(NSStringFromSelector(selector))"
        lock.withLock {
            protectedSelectors.insert(key)
        }
    }

    public func validateProtectedSelectors() -> Bool {
        lock.withLock { !protectedSelectors.isEmpty }
    }
}
