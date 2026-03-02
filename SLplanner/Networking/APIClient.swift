import Foundation

enum APIError: LocalizedError {
    case invalidResponse(statusCode: Int)
    case decodingFailed(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse(let code):
            "Server returned status \(code)"
        case .decodingFailed(let error):
            "Failed to parse response: \(error.localizedDescription)"
        case .networkError(let error):
            error.localizedDescription
        }
    }

    var userFacingMessage: String {
        switch self {
        case .networkError(let underlying):
            let code = (underlying as NSError).code
            if code == NSURLErrorNotConnectedToInternet || code == NSURLErrorNetworkConnectionLost {
                return "No internet connection. Try again later."
            }
            return "Network issue. Check your connection and try again."
        case .invalidResponse:
            return "Server error. Please try again later."
        case .decodingFailed:
            return "Unexpected response from the server."
        }
    }

    static func userFacingMessage(for error: Error) -> String {
        (error as? APIError)?.userFacingMessage ?? "Something went wrong. Try again later."
    }
}

final class APIClient: Sendable {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    func fetch<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(from: endpoint.url)
        } catch {
            throw APIError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw APIError.invalidResponse(statusCode: code)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }
}
