import Foundation

/// Protocol that defines standard response parsing operations.
public protocol ResponseParsing {
    /// Decodes a generic Codable model from the received raw payload.
    func parse<T: Codable>(data: Data, response: URLResponse) throws -> T
}

/// Generic response parser implementation to validate status codes and decode JSON data.
public final class ResponseParser: ResponseParsing {
    
    private let decoder: JSONDecoder
    
    public init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }
    
    /// Parses and decodes the response, mapping exceptions to localized APIErrors.
    public func parse<T: Codable>(data: Data, response: URLResponse) throws -> T {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingFailed(error)
            }
        case 401:
            throw APIError.unauthorized
        default:
            throw APIError.unacceptedStatusCode(httpResponse.statusCode)
        }
    }
}
