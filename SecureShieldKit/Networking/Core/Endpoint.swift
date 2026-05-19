import Foundation

/// Represents a networking endpoint structure.
public protocol Endpoint {
    /// The base URL (e.g., "https://api.example.com")
    var baseURL: String { get }
    
    /// The specific path (e.g., "/v1/users")
    var path: String { get }
    
    /// The HTTP method for the request
    var method: HTTPMethod { get }
    
    /// Headers to include in the request
    var headers: [String: String]? { get }
    
    /// Query parameters to append to the URL
    var queryParameters: [String: String]? { get }
    
    /// The encoded body of the request (for POST/PUT)
    var body: Data? { get }
}

public extension Endpoint {
    /// Builds the complete URLRequest from the Endpoint properties.
    func asURLRequest() throws -> URLRequest {
        guard var urlComponents = URLComponents(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        
        // Append Query Parameters
        if let queryParameters = queryParameters, !queryParameters.isEmpty {
            urlComponents.queryItems = queryParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let finalURL = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        // Default Headers
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil && request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        // Custom Headers
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        return request
    }
}
