import Foundation

struct SuggestedPlace: Decodable {
    let title: String
    let subtitle: String
    let description: String
    let category: String
    let localTitle: String?
    let localDescription: String?
}

enum GeminiServiceError: Error {
    case badResponse
}

private struct SuggestionsRequestBody: Encodable {
    let prompt: String
    let constraints: String
    let likedTitles: [String]
    let blacklistedTitles: [String]
    let alreadySuggestedTitles: [String]
    let count: Int
}

enum GeminiService {
    static func fetchPlaces(prompt: String,
                            constraints: String,
                            likedTitles: [String],
                            blacklistedTitles: [String],
                            alreadySuggestedTitles: [String],
                            count: Int) async throws -> [SuggestedPlace] {
        let body = SuggestionsRequestBody(prompt: prompt,
                                          constraints: constraints,
                                          likedTitles: likedTitles,
                                          blacklistedTitles: blacklistedTitles,
                                          alreadySuggestedTitles: alreadySuggestedTitles,
                                          count: count)
        let httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await BackendClient.sendAuthenticated {
            var request = URLRequest(url: URL(string: "\(Config.backendBaseURL)/v1/suggestions")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(Config.appSharedSecret, forHTTPHeaderField: "x-app-secret")
            request.httpBody = httpBody
            return request
        }
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("GeminiService: suggestions request failed, status=\(status) body=\(String(data: data, encoding: .utf8) ?? "<none>")")
            throw GeminiServiceError.badResponse
        }

        return try JSONDecoder().decode([SuggestedPlace].self, from: data)
    }
}
