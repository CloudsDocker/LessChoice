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
        guard isSupported else { return nil }

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
            await reportDebug("assertionHeaders failed: \(error)")
            return nil
        }
    }

    // Temporary: surfaces client-side App Attest failures in Cloud Run logs since
    // there's no Xcode console access to the physical test device. Remove once
    // rollout is stable.
    private static func reportDebug(_ message: String) async {
        var request = URLRequest(url: URL(string: "\(Config.backendBaseURL)/v1/debug-log")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Config.appSharedSecret, forHTTPHeaderField: "x-app-secret")
        request.httpBody = try? JSONEncoder().encode(["message": message])
        _ = try? await URLSession.shared.data(for: request)
    }

    private static func ensureRegisteredKeyId() async throws -> String {
        if let existing = KeychainStore.read(keyIdKeychainKey) {
            return existing
        }

        let keyId: String
        do {
            keyId = try await DCAppAttestService.shared.generateKey()
        } catch {
            await reportDebug("generateKey failed: \(error)")
            throw error
        }

        let challenge = try await fetchChallenge()
        let clientDataHash = Data(SHA256.hash(data: Data(challenge.utf8)))

        let attestation: Data
        do {
            attestation = try await DCAppAttestService.shared.attestKey(keyId, clientDataHash: clientDataHash)
        } catch {
            await reportDebug("attestKey failed: \(error)")
            throw error
        }

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

        let (_, response) = try await BackendClient.dataWithColdStartRetry(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AppAttestError.backendError
        }
    }
}
