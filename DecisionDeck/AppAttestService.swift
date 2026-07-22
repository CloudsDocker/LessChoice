import CryptoKit
import DeviceCheck
import Foundation

enum AppAttestError: Error {
    case unsupported
    case backendError
}

/// Proves to the backend that requests genuinely come from this app running on real
/// Apple hardware, not a script that extracted the shared secret from the App Store
/// binary. One-time key generation + attestation on first use, then a fresh signed
/// assertion per protected request.
enum AppAttestService {
    private static let keyIdKeychainKey = "appAttestKeyId"

    private static var isSupported: Bool {
        DCAppAttestService.shared.isSupported
    }

    /// Headers to attach to a protected backend request. Returns nil if App Attest
    /// isn't available (e.g. older devices) — callers should still send the request,
    /// the backend simply won't be able to enforce attestation for it.
    static func assertionHeaders() async -> [String: String]? {
        guard isSupported else {
            print("AppAttestService: DCAppAttestService.isSupported == false (are we running in Simulator?)")
            return nil
        }

        let maxAttempts = 3
        for attempt in 1...maxAttempts {
            do {
                let keyId = try await ensureRegisteredKeyId()
                let challenge = try await fetchChallenge()
                let clientDataHash = Data(SHA256.hash(data: Data(challenge.utf8)))
                let assertion = try await DCAppAttestService.shared.generateAssertion(keyId, clientDataHash: clientDataHash)

                return [
                    "x-key-id": keyId,
                    "x-assertion": assertion.base64EncodedString(),
                    "x-challenge": challenge
                ]
            } catch {
                print("AppAttestService: attempt \(attempt)/\(maxAttempts) failed to build assertion headers: \(error)")

                let nsError = error as NSError
                if nsError.domain == "com.apple.devicecheck.error" && nsError.code == 3 {
                    // DCError.invalidKey: the Secure Enclave no longer recognizes this key
                    // (e.g. the app was reinstalled under a different App Attest entitlement
                    // environment — development vs production — which orphans prior keys).
                    // Our cached key ID is now permanently unusable; drop it so the next
                    // attempt generates and registers a fresh one instead of repeating the
                    // same failure.
                    print("AppAttestService: clearing stale key ID after invalidKey error")
                    KeychainStore.delete(keyIdKeychainKey)
                }

                if attempt < maxAttempts {
                    try? await Task.sleep(nanoseconds: UInt64(attempt) * 1_000_000_000)
                }
            }
        }
        return nil
    }

    private static func ensureRegisteredKeyId() async throws -> String {
        if let existing = KeychainStore.read(keyIdKeychainKey) {
            return existing
        }

        let keyId = try await DCAppAttestService.shared.generateKey()
        let challenge = try await fetchChallenge()
        let clientDataHash = Data(SHA256.hash(data: Data(challenge.utf8)))
        let attestation = try await DCAppAttestService.shared.attestKey(keyId, clientDataHash: clientDataHash)

        try await register(keyId: keyId, attestation: attestation, challenge: challenge)
        KeychainStore.write(keyId, for: keyIdKeychainKey)
        return keyId
    }

    private static func fetchChallenge() async throws -> String {
        var request = URLRequest(url: URL(string: "\(Config.backendBaseURL)/v1/attest/challenge")!)
        request.httpMethod = "POST"
        request.setValue(Config.appSharedSecret, forHTTPHeaderField: "x-app-secret")

        let (data, response) = try await BackendClient.dataWithColdStartRetry(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("AppAttestService: challenge fetch failed, status=\(status) body=\(String(data: data, encoding: .utf8) ?? "<none>")")
            throw AppAttestError.backendError
        }
        struct ChallengeResponse: Decodable { let challenge: String }
        return try JSONDecoder().decode(ChallengeResponse.self, from: data).challenge
    }

    private static func register(keyId: String, attestation: Data, challenge: String) async throws {
        var request = URLRequest(url: URL(string: "\(Config.backendBaseURL)/v1/attest/register")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Config.appSharedSecret, forHTTPHeaderField: "x-app-secret")

        let body: [String: String] = [
            "keyId": keyId,
            "attestation": attestation.base64EncodedString(),
            "challenge": challenge
        ]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await BackendClient.dataWithColdStartRetry(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("AppAttestService: register failed, status=\(status) body=\(String(data: data, encoding: .utf8) ?? "<none>")")
            throw AppAttestError.backendError
        }
    }
}
