import SwiftUI
import Combine

// MARK: - 1. Host Project Models
public struct UserProfile: Codable, Identifiable {
    public let id: Int
    public let name: String
    public let email: String
    public let role: String
}

public struct APIStatusResponse: Codable {
    public let success: Bool
    public let message: String
}

// MARK: - 2. Host Project API Service (Clean Architecture Data Source)
public protocol UserNetworkServiceProtocol {
    func getUserProfile(userId: Int) async throws -> UserProfile
    func updateProfilePicture(userId: Int, imageData: Data) async throws -> APIStatusResponse
}

public final class UserNetworkService: UserNetworkServiceProtocol {
    private let apiManager: APIManaging
    
    /// Dependency Injection implementation
    public init(apiManager: APIManaging = APIManager(baseURL: URL(string: "https://api.example.com")!)) {
        self.apiManager = apiManager
    }
    
    public func getUserProfile(userId: Int) async throws -> UserProfile {
        return try await apiManager.request(
            endpoint: "/users/\(userId)",
            method: .get,
            parameters: nil,
            headers: ["Accept": "application/json"],
            responseModel: UserProfile.self
        )
    }
    
    public func updateProfilePicture(userId: Int, imageData: Data) async throws -> APIStatusResponse {
        return try await apiManager.uploadImage(
            endpoint: "/users/\(userId)/avatar",
            imageData: imageData,
            filename: "avatar.jpg",
            mimeType: "image/jpeg",
            parameters: ["userId": "\(userId)"],
            headers: nil,
            responseModel: APIStatusResponse.self
        )
    }
}

// MARK: - 3. Example ViewModel (MVVM Architecture)
@MainActor
public final class UserProfileViewModel: ObservableObject {
    @Published public private(set) var state: ViewState = .idle
    
    public enum ViewState {
        case idle
        case loading
        case success(UserProfile)
        case error(String)
    }
    
    private let service: UserNetworkServiceProtocol
    
    public init(service: UserNetworkServiceProtocol = UserNetworkService()) {
        self.service = service
    }
    
    /// Loads a user profile with strict error handling and view state updates.
    public func loadUserProfile(id: Int) {
        state = .loading
        Task {
            do {
                let profile = try await service.getUserProfile(userId: id)
                self.state = .success(profile)
            } catch let error as APIError {
                self.state = .error(error.errorDescription ?? "An unexpected API error occurred.")
            } catch {
                self.state = .error(error.localizedDescription)
            }
        }
    }
}

// MARK: - 4. Example SwiftUI View (Premium Design Integration)
public struct ExampleUserProfileView: View {
    @StateObject private var viewModel = UserProfileViewModel()
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ZStack {
                // Harmonic Dark Background
                LinearGradient(
                    colors: [Color(red: 0.08, green: 0.09, blue: 0.13), Color(red: 0.05, green: 0.05, blue: 0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack {
                    switch viewModel.state {
                    case .idle:
                        idleStateView
                    case .loading:
                        loadingStateView
                    case .success(let user):
                        profileCardView(user: user)
                    case .error(let message):
                        errorStateView(message: message)
                    }
                }
                .navigationTitle("Network Security Shield")
                .navigationBarTitleDisplayMode(.inline)
            }
            .preferredColorScheme(.dark)
        }
    }
    
    private var idleStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "shield.dashed")
                .font(.system(size: 64))
                .foregroundColor(.blue)
            
            Text("Ready for Secure API Operations")
                .font(.headline)
                .foregroundColor(.white)
            
            Button(action: { viewModel.loadUserProfile(id: 101) }) {
                Text("Fetch Profile Securely")
                   // .fontWeight(.medium)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal, 40)
            }
        }
    }
    
    private var loadingStateView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(1.5)
            
            Text("Processing Requests via Secure SDK...")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    private func profileCardView(user: UserProfile) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "person.crop.circle.fill.badge.checkmark")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 8) {
                Text(user.name)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(user.role.uppercased())
                    .font(.caption2)
                    //.fontWeight(.bold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.15))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
            .padding(.bottom, 10)
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            Button(action: { viewModel.loadUserProfile(id: 101) }) {
                Label("Refresh Request", systemImage: "arrow.clockwise")
                  //  .fontWeight(.medium)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
    }
    
    private func errorStateView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 64))
                .foregroundColor(.red)
            
            Text("API Request Interrupted")
                .font(.headline)
                .foregroundColor(.white)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: { viewModel.loadUserProfile(id: 101) }) {
                Text("Retry Connection")
                    //.fontWeight(.medium)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.2))
                    .foregroundColor(.red)
                    .cornerRadius(12)
                    .padding(.horizontal, 40)
            }
        }
    }
}

// MARK: - 5. Generic Secure Service (Accessible from Outside)

public struct TMDBService: Sendable {
    private let bearerToken = "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJjNDZiYTc5Y2Y2ZTA4OWY5YzI5NjY0MmE3NzE4OGEyZiIsIm5iZiI6MTc3NzI2NzQ3My4xNzEsInN1YiI6IjY5ZWVmMzExMmRlNGU2N2FlYjI4ZTA2NSIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.1ioYVqRRXRP425rYtTQxKvLQ-aA6OnodN5BVwZ_ZJTw"
    
    private let networkingClient = PinnedNetworkingClient()
    public let baseURL: String
    
    public init(baseURL: String = "") {
        self.baseURL = baseURL
    }
    
    /// A generic API call method that executes a URLRequest and decodes the JSON response into a generic Decodable type.
    public func fetchGeneric<T: Decodable>(
        baseURL: String? = nil,
        endpoint: String,
        httpMethod: String = "GET",
        headers: [String: String]? = nil,
        timeInterval: TimeInterval = 10,
        bearerToken: String? = nil
    ) async throws -> T {
        let finalBaseURL = baseURL ?? self.baseURL
        let urlString: String
        if finalBaseURL.isEmpty {
            urlString = endpoint
        } else {
            let hasSlash = finalBaseURL.hasSuffix("/") || endpoint.hasPrefix("/")
            urlString = hasSlash ? "\(finalBaseURL)\(endpoint)" : "\(finalBaseURL)/\(endpoint)"
        }
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.timeoutInterval = timeInterval
        
        var allHeaders = [
            "accept": "application/json"
        ]
        
        let token = bearerToken ?? self.bearerToken
        if !token.isEmpty {
            allHeaders["Authorization"] = "Bearer \(token)"
        }
        
        if let customHeaders = headers {
            for (key, value) in customHeaders {
                allHeaders[key] = value
            }
        }
        
        request.allHTTPHeaderFields = allHeaders
        
        let (data, _) = try await networkingClient.data(for: request)
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    public func fetchNowPlaying<T: Decodable>(
        baseURL: String? = nil,
        endpoint: String,
        httpMethod: String = "GET",
        headers: [String: String]? = nil,
        timeInterval: TimeInterval = 10,
        bearerToken: String? = nil
    ) async throws -> T {
        return try await fetchGeneric(
            baseURL: baseURL,
            endpoint: endpoint,
            httpMethod: httpMethod,
            headers: headers,
            timeInterval: timeInterval,
            bearerToken: bearerToken
        )
    }
    
    public func fetchPopular<T: Decodable>(
        baseURL: String? = nil,
        endpoint: String,
        httpMethod: String = "GET",
        headers: [String: String]? = nil,
        timeInterval: TimeInterval = 10,
        bearerToken: String? = nil
    ) async throws -> T {
        return try await fetchGeneric(
            baseURL: baseURL,
            endpoint: endpoint,
            httpMethod: httpMethod,
            headers: headers,
            timeInterval: timeInterval,
            bearerToken: bearerToken
        )
    }
    
    public func fetchTopRate<T: Decodable>(
        baseURL: String? = nil,
        endpoint: String,
        httpMethod: String = "GET",
        headers: [String: String]? = nil,
        timeInterval: TimeInterval = 10,
        bearerToken: String? = nil
    ) async throws -> T {
        return try await fetchGeneric(
            baseURL: baseURL,
            endpoint: endpoint,
            httpMethod: httpMethod,
            headers: headers,
            timeInterval: timeInterval,
            bearerToken: bearerToken
        )
    }
    
    public func fetchUpcoming<T: Decodable>(
        baseURL: String? = nil,
        endpoint: String,
        httpMethod: String = "GET",
        headers: [String: String]? = nil,
        timeInterval: TimeInterval = 10,
        bearerToken: String? = nil
    ) async throws -> T {
        return try await fetchGeneric(
            baseURL: baseURL,
            endpoint: endpoint,
            httpMethod: httpMethod,
            headers: headers,
            timeInterval: timeInterval,
            bearerToken: bearerToken
        )
    }
    
    public func searchMovies<T: Decodable>(
        baseURL: String? = nil,
        endpoint: String,
        httpMethod: String = "GET",
        headers: [String: String]? = nil,
        timeInterval: TimeInterval = 10,
        bearerToken: String? = nil
    ) async throws -> T {
        return try await fetchGeneric(
            baseURL: baseURL,
            endpoint: endpoint,
            httpMethod: httpMethod,
            headers: headers,
            timeInterval: timeInterval,
            bearerToken: bearerToken
        )
    }
    
    public func fetchAccountDetails<T: Decodable>(
        baseURL: String? = nil,
        endpoint: String,
        httpMethod: String = "GET",
        headers: [String: String]? = nil,
        timeInterval: TimeInterval = 10,
        bearerToken: String? = nil
    ) async throws -> T {
        return try await fetchGeneric(
            baseURL: baseURL,
            endpoint: endpoint,
            httpMethod: httpMethod,
            headers: headers,
            timeInterval: timeInterval,
            bearerToken: bearerToken
        )
    }
    
    public func fetchPeopleChanges<T: Decodable>(
        baseURL: String? = nil,
        endpoint: String,
        httpMethod: String = "GET",
        headers: [String: String]? = nil,
        timeInterval: TimeInterval = 10,
        bearerToken: String? = nil
    ) async throws -> T {
        return try await fetchGeneric(
            baseURL: baseURL,
            endpoint: endpoint,
            httpMethod: httpMethod,
            headers: headers,
            timeInterval: timeInterval,
            bearerToken: bearerToken
        )
    }
}


