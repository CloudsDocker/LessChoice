import Foundation

struct SuggestedPlace: Decodable {
    let title: String
    let subtitle: String
    let description: String
    let category: String
}

enum GeminiServiceError: Error {
    case badResponse
    case emptyContent
}

enum GeminiService {
    static func fetchPlaces(prompt: String,
                            constraints: String,
                            likedTitles: [String],
                            blacklistedTitles: [String],
                            alreadySuggestedTitles: [String],
                            count: Int) async throws -> [SuggestedPlace] {
        let instructions = """
        You are recommending real, specific named places for a trip decision app.
        Context: \(prompt)
        Constraints: \(constraints)
        Suggest \(count) new distinct real places that fit the context and constraints.
        \(likedTitles.isEmpty ? "" : "The user liked these places, favor a similar style/category/vibe: \(likedTitles.joined(separator: ", ")).")
        \(blacklistedTitles.isEmpty ? "" : "The user disliked these places, avoid them and anything similar in style or category: \(blacklistedTitles.joined(separator: ", ")).")
        \(alreadySuggestedTitles.isEmpty ? "" : "Do not repeat any of these already-suggested places: \(alreadySuggestedTitles.joined(separator: ", ")).")
        Respond with ONLY a JSON array, no markdown fences, in this exact shape:
        [{"title": "Place Name", "subtitle": "short tagline", "description": "one engaging sentence under 140 characters", "category": "one or two words"}]
        """

        var request = URLRequest(url: URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(Config.geminiAPIKey)")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "contents": [["parts": [["text": instructions]]]],
            "generationConfig": ["response_mime_type": "application/json"]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw GeminiServiceError.badResponse
        }

        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = decoded.candidates.first?.content.parts.first?.text,
              let jsonData = text.data(using: .utf8) else {
            throw GeminiServiceError.emptyContent
        }

        return try JSONDecoder().decode([SuggestedPlace].self, from: jsonData)
    }
}

private struct GeminiResponse: Decodable {
    struct Candidate: Decodable {
        struct Content: Decodable {
            struct Part: Decodable {
                let text: String
            }
            let parts: [Part]
        }
        let content: Content
    }
    let candidates: [Candidate]
}
