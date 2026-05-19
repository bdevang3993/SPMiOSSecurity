import Foundation

/// Defines all possible errors that can occur during network requests.
public enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case unacceptedStatusCode(Int)
    case decodingFailed(Error)
    case encodingFailed(Error)
    case unauthorized
    case timeout
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL provided is invalid."
        case .requestFailed(let error):
            return "Network request failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "The server response was invalid or unrecognized."
        case .unacceptedStatusCode(let code):
            return "The server returned an unacceptable status code: \(code)."
        case .decodingFailed(let error):
            return "Failed to decode the response: \(error.localizedDescription)"
        case .encodingFailed(let error):
            return "Failed to encode the request body: \(error.localizedDescription)"
        case .unauthorized:
            return "The request is unauthorized. Please check your credentials."
        case .timeout:
            return "The request timed out."
        }
    }
}
