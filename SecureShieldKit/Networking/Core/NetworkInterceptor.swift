import Foundation

/// Protocol for intercepting URLRequests before they are sent.
/// Useful for appending auth tokens or modifying headers globally.
public protocol NetworkInterceptor {
    func adapt(_ request: URLRequest) async throws -> URLRequest
}

/// Example of an Authentication Interceptor that injects a Bearer token.
public struct AuthInterceptor: NetworkInterceptor {
    private let tokenProvider: () async -> String?
    
    /// Initializes with a closure that returns an optional token.
    public init(tokenProvider: @escaping () async -> String?) {
        self.tokenProvider = tokenProvider
    }
    
    public func adapt(_ request: URLRequest) async throws -> URLRequest {
        var modifiedRequest = request
        if let token = await tokenProvider() {
            modifiedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return modifiedRequest
    }
}
