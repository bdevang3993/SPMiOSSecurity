import Foundation

/// Protocol defining standard properties required to construct a network request.
public protocol APIEndpoint {
    /// The base URL of the service (e.g., https://api.example.com)
    var baseURL: URL { get }
    
    /// The path component for the request (e.g., /v1/users)
    var path: String { get }
    
    /// The HTTP Method (GET, POST, PUT, DELETE, etc.)
    var method: HTTPMethod { get }
    
    /// HTTP headers specific to this endpoint.
    var headers: [String: String]? { get }
    
    /// Query parameters appended to the URL.
    var queryParameters: [String: String]? { get }
    
    /// Key-value dictionary representing JSON request body.
    var body: [String: Any]? { get }
}
