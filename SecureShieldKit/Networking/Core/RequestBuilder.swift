import Foundation

/// A builder class that constructs URLRequest objects in a clean, chainable manner.
public final class RequestBuilder {
    
    private var url: URL?
    private var method: HTTPMethod = .get
    private var headers: [String: String] = [:]
    private var queryParameters: [String: String] = [:]
    private var body: [String: Any]?
    private var timeoutInterval: TimeInterval = 30.0
    
    public init() {}
    
    /// Set the destination URL directly.
    @discardableResult
    public func set(url: URL) -> RequestBuilder {
        self.url = url
        return self
    }
    
    /// Set a path to append to a base URL.
    @discardableResult
    public func set(path: String, baseURL: URL) -> RequestBuilder {
        self.url = baseURL.appendingPathComponent(path)
        return self
    }
    
    /// Set the HTTP Method.
    @discardableResult
    public func set(method: HTTPMethod) -> RequestBuilder {
        self.method = method
        return self
    }
    
    /// Add headers. Existing keys are overwritten by new ones.
    @discardableResult
    public func add(headers: [String: String]?) -> RequestBuilder {
        guard let headers = headers else { return self }
        self.headers.merge(headers) { (_, new) in new }
        return self
    }
    
    /// Add query parameters.
    @discardableResult
    public func add(queryParameters: [String: String]?) -> RequestBuilder {
        guard let queryParameters = queryParameters else { return self }
        self.queryParameters.merge(queryParameters) { (_, new) in new }
        return self
    }
    
    /// Set the request body parameters to be serialized as JSON.
    @discardableResult
    public func set(body: [String: Any]?) -> RequestBuilder {
        self.body = body
        return self
    }
    
    /// Set custom request timeout interval.
    @discardableResult
    public func set(timeoutInterval: TimeInterval) -> RequestBuilder {
        self.timeoutInterval = timeoutInterval
        return self
    }
    
    /// Build and return the completed URLRequest.
    /// - Throws: APIError if URL or serialization fails.
    public func build() throws -> URLRequest {
        guard let targetURL = url else {
            throw APIError.invalidURL
        }
        
        guard var components = URLComponents(url: targetURL, resolvingAgainstBaseURL: true) else {
            throw APIError.invalidURL
        }
        
        if !queryParameters.isEmpty {
            components.queryItems = queryParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let finalURL = components.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = method.rawValue
        request.timeoutInterval = timeoutInterval
        
        // Apply headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add content-type if not already defined and body is present
        if let body = body {
            if request.value(forHTTPHeaderField: "Content-Type") == nil {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            } catch {
                throw APIError.encodingFailed(error)
            }
        }
        
        return request
    }
}
