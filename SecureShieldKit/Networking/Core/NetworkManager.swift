import Foundation

/// Protocol defining the network operations, enabling dependency injection/mocking.
public protocol NetworkManaging {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    func uploadImage<T: Decodable>(_ endpoint: Endpoint, imageData: Data, filename: String, mimeType: String) async throws -> T
}

/// The main generic APIManager class handling network requests.
public final class NetworkManager: NetworkManaging {
    
    private let session: URLSession
    private let interceptors: [NetworkInterceptor]
    
    /// Shared singleton instance if needed. In clean architecture, prefer dependency injection.
    public static let shared = NetworkManager()
    
    /// Initialize with custom configuration and interceptors.
    /// - Parameters:
    ///   - timeoutInterval: Default timeout for requests.
    ///   - interceptors: Array of interceptors to modify requests (e.g., auth tokens).
    public init(timeoutInterval: TimeInterval = 30.0, interceptors: [NetworkInterceptor] = []) {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeoutInterval
        configuration.timeoutIntervalForResource = timeoutInterval * 2
        
        self.session = URLSession(configuration: configuration)
        self.interceptors = interceptors
    }
    
    /// Executes a network request and decodes the generic response.
    public func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        var urlRequest = try endpoint.asURLRequest()
        
        // Apply Interceptors (e.g., attaching Auth Tokens)
        for interceptor in interceptors {
            urlRequest = try await interceptor.adapt(urlRequest)
        }
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch let urlError as URLError {
            if urlError.code == .timedOut {
                throw APIError.timeout
            } else {
                throw APIError.requestFailed(urlError)
            }
        } catch {
            throw APIError.requestFailed(error)
        }
        
        try validate(response: response)
        
        return try decode(data: data)
    }
    
    /// Handles image uploading using multipart/form-data.
    public func uploadImage<T: Decodable>(_ endpoint: Endpoint, imageData: Data, filename: String, mimeType: String = "image/jpeg") async throws -> T {
        var urlRequest = try endpoint.asURLRequest()
        
        let boundary = "Boundary-\(UUID().uuidString)"
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add image data
        if let boundaryPrefix = "--\(boundary)\r\n".data(using: .utf8),
           let contentDisposition = "Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8),
           let contentType = "Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8),
           let newline = "\r\n".data(using: .utf8),
           let boundarySuffix = "--\(boundary)--\r\n".data(using: .utf8) {
            
            body.append(boundaryPrefix)
            body.append(contentDisposition)
            body.append(contentType)
            body.append(imageData)
            body.append(newline)
            body.append(boundarySuffix)
        }
        
        urlRequest.httpBody = body
        
        // Apply Interceptors
        for interceptor in interceptors {
            urlRequest = try await interceptor.adapt(urlRequest)
        }
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.upload(for: urlRequest, from: body)
        } catch {
            throw APIError.requestFailed(error)
        }
        
        try validate(response: response)
        
        return try decode(data: data)
    }
    
    // MARK: - Helper Methods
    
    private func validate(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return // Success
        case 401:
            throw APIError.unauthorized
        default:
            throw APIError.unacceptedStatusCode(httpResponse.statusCode)
        }
    }
    
    private func decode<T: Decodable>(data: Data) throws -> T {
        let decoder = JSONDecoder()
        // You can configure dateDecodingStrategy or keyDecodingStrategy here
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }
}
