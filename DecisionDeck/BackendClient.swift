import Foundation

enum BackendClient {
    /// Cloud Run scales to zero when idle, so the request that wakes it up can
    /// occasionally hit a 502 while the new instance is still starting. One retry
    /// after a short delay is enough to ride that out without adding real latency
    /// to the common case.
    static func dataWithColdStartRetry(for request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 502 || http.statusCode == 503 {
                throw URLError(.badServerResponse)
            }
            return (data, response)
        } catch {
            try await Task.sleep(nanoseconds: 1_500_000_000)
            return try await URLSession.shared.data(for: request)
        }
    }
}
