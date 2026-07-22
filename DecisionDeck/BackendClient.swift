import Foundation

enum BackendClient {
    /// Cloud Run scales to zero when idle, so the request that wakes it up can
    /// occasionally hit a 502 while the new instance is still starting. One retry
    /// after a short delay is enough to ride that out without adding real latency
    /// to the common case.
    ///
    /// Only safe for requests that are NOT App Attest–authenticated — a challenge/
    /// assertion is single-use, so a verbatim resend would be rejected. Use
    /// `sendAuthenticated` for protected endpoints instead.
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

    /// Sends an App Attest–authenticated request. Each assertion carries a single-use
    /// challenge AND a strictly-increasing hardware counter, so a failed request can
    /// never be replayed verbatim — the retry must carry a *fresh* assertion. This
    /// rebuilds the attestation headers on every attempt (unlike a blind resend), which
    /// is what makes cold-start recovery safe for protected endpoints. `makeRequest`
    /// must return the base request WITHOUT any App Attest headers; those are added here.
    static func sendAuthenticated(_ makeRequest: @Sendable () -> URLRequest) async throws -> (Data, URLResponse) {
        let maxAttempts = 3
        var lastError: Error?
        for attempt in 1...maxAttempts {
            var request = makeRequest()
            if let headers = await AppAttestService.assertionHeaders() {
                for (field, value) in headers {
                    request.setValue(value, forHTTPHeaderField: field)
                }
            }
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                if (status == 502 || status == 503) && attempt < maxAttempts {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    continue
                }
                return (data, response)
            } catch {
                lastError = error
                if attempt < maxAttempts {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    continue
                }
            }
        }
        throw lastError ?? URLError(.unknown)
    }
}
