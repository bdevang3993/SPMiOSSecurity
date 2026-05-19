import Foundation

public extension URLSession {
    
    /// Creates a customized URLSession configured for secure, production-level API communications.
    /// - Parameter timeout: Maximum request time limits.
    /// - Returns: A configured URLSession instance.
    static func secureSession(timeout: TimeInterval = 30.0) -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout * 2
        configuration.waitsForConnectivity = true
        
        // Strict cookie and caching policy to maintain maximum api protection in SDK
        configuration.httpCookieAcceptPolicy = .never
        configuration.httpShouldSetCookies = false
        
        return URLSession(configuration: configuration)
    }
}
