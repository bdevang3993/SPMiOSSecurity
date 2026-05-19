import Foundation

/// Protocol defining expectations for a type that manages authentication tokens.
public protocol TokenProviding: AnyObject {
    /// Retrieve the current authentication token.
    func fetchToken() async -> String?
    
    /// Persist or cache the token.
    func saveToken(_ token: String) async
    
    /// Remove the cached token.
    func clearToken() async
}

/// A thread-safe manager for accessing and updating credentials.
public final class TokenManager: TokenProviding {
    
    /// Shared singleton instance.
    public static let shared = TokenManager()
    
    private var token: String?
    private let lock = NSLock()
    
    private init() {}
    
    /// Fetches the cached bearer token thread-safely.
    public func fetchToken() async -> String? {
        lock.withLock {
            return token
        }
    }
    
    /// Updates the cached bearer token thread-safely.
    public func saveToken(_ token: String) async {
        lock.withLock {
            self.token = token
        }
    }
    
    /// Clears the cached bearer token thread-safely.
    public func clearToken() async {
        lock.withLock {
            self.token = nil
        }
    }
}
