import Foundation

/// Protocol that outlines essential functionality required for executing API network calls.
public protocol APIManaging {
    
    /// Executes a dynamic API request and decodes the generic response.
    func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod,
        parameters: [String: Any]?,
        headers: [String: String]?,
        responseModel: T.Type
    ) async throws -> T
    
    /// Executes a multipart/form-data upload request for media items and decodes the response.
    func uploadImage<T: Codable>(
        endpoint: String,
        imageData: Data,
        filename: String,
        mimeType: String,
        parameters: [String: String]?,
        headers: [String: String]?,
        responseModel: T.Type
    ) async throws -> T
}

/// The core class managing dynamic REST API networking operations using URLSession.
public final class APIManager: APIManaging {
    
    private let session: URLSession
    private let parser: ResponseParsing
    private let tokenManager: TokenProviding
    private let baseURL: URL?
    
    /// Initialize with essential networking configuration.
    /// - Parameters:
    ///   - baseURL: Default prefix path URL.
    ///   - session: Customized URLSession.
    ///   - parser: Data decoding system.
    ///   - tokenManager: Security bearer tokens manager.
    public init(
        baseURL: URL? = nil,
        session: URLSession = .secureSession(),
        parser: ResponseParsing = ResponseParser(),
        tokenManager: TokenProviding = TokenManager.shared
    ) {
        self.baseURL = baseURL
        self.session = session
        self.parser = parser
        self.tokenManager = tokenManager
    }
    
    /// Executes a dynamic network request and parses the Generic Response model.
    public func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        responseModel: T.Type
    ) async throws -> T {
        
        let builder = RequestBuilder()
        
        // Resolve dynamic endpoints safely
        if let absoluteURL = URL(string: endpoint), absoluteURL.scheme != nil {
            builder.set(url: absoluteURL)
        } else if let base = baseURL {
            builder.set(path: endpoint, baseURL: base)
        } else {
            throw APIError.invalidURL
        }
        
        // Handle parameters strategically based on request method types
        if method == .get || method == .delete {
            if let params = parameters {
                let queryItems = params.mapValues { "\($0)" }
                builder.add(queryParameters: queryItems)
            }
        } else {
            builder.set(body: parameters)
        }
        
        // Setup Method and Headers
        builder.set(method: method)
        builder.add(headers: headers)
        
        // Inject Bearer tokens automatically if active
        if let token = await tokenManager.fetchToken() {
            builder.add(headers: ["Authorization": "Bearer \(token)"])
        }
        
        let request = try builder.build()
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            if urlError.code == .timedOut {
                throw APIError.timeout
            } else {
                throw APIError.requestFailed(urlError)
            }
        } catch {
            throw APIError.requestFailed(error)
        }
        
        return try parser.parse(data: data, response: response)
    }
    
    /// Handles multipart form image upload.
    public func uploadImage<T: Codable>(
        endpoint: String,
        imageData: Data,
        filename: String,
        mimeType: String = "image/jpeg",
        parameters: [String: String]? = nil,
        headers: [String: String]? = nil,
        responseModel: T.Type
    ) async throws -> T {
        
        var form = MultipartForm()
        form.append(fileData: imageData, name: "file", filename: filename, mimeType: mimeType)
        
        if let parameters = parameters {
            for (key, value) in parameters {
                form.append(value: value, name: key)
            }
        }
        
        let bodyData = form.finalize()
        
        let builder = RequestBuilder()
        
        if let absoluteURL = URL(string: endpoint), absoluteURL.scheme != nil {
            builder.set(url: absoluteURL)
        } else if let base = baseURL {
            builder.set(path: endpoint, baseURL: base)
        } else {
            throw APIError.invalidURL
        }
        
        builder.set(method: .post)
        builder.add(headers: headers)
        builder.add(headers: ["Content-Type": "multipart/form-data; boundary=\(form.boundary)"])
        
        if let token = await tokenManager.fetchToken() {
            builder.add(headers: ["Authorization": "Bearer \(token)"])
        }
        
        var request = try builder.build()
        request.httpBody = bodyData
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.upload(for: request, from: bodyData)
        } catch {
            throw APIError.requestFailed(error)
        }
        
        return try parser.parse(data: data, response: response)
    }
}
