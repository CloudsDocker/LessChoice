import Foundation

actor PlacesPhotoCache {
    static let shared = PlacesPhotoCache()
    private var cache: [String: URL?] = [:]

    func cachedURL(for key: String) -> URL?? {
        cache[key]
    }

    func store(_ url: URL?, for key: String) {
        cache[key] = url
    }
}

enum PlacesService {
    static func photoURL(forPlace title: String, context: String) async -> URL? {
        let cacheKey = "\(title.lowercased())|\(context.lowercased())"
        if let cached = await PlacesPhotoCache.shared.cachedURL(for: cacheKey) {
            return cached
        }

        guard let reference = try? await photoReference(forPlace: title, context: context) else {
            await PlacesPhotoCache.shared.store(nil, for: cacheKey)
            return nil
        }
        var components = URLComponents(string: "https://maps.googleapis.com/maps/api/place/photo")!
        components.queryItems = [
            URLQueryItem(name: "maxwidth", value: "800"),
            URLQueryItem(name: "photo_reference", value: reference),
            URLQueryItem(name: "key", value: Config.googlePlacesAPIKey)
        ]
        let url = components.url
        await PlacesPhotoCache.shared.store(url, for: cacheKey)
        return url
    }

    private static func photoReference(forPlace title: String, context: String) async throws -> String? {
        var components = URLComponents(string: "https://maps.googleapis.com/maps/api/place/textsearch/json")!
        components.queryItems = [
            URLQueryItem(name: "query", value: "\(title) \(context)"),
            URLQueryItem(name: "key", value: Config.googlePlacesAPIKey)
        ]
        let (data, response) = try await URLSession.shared.data(from: components.url!)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return nil
        }
        let decoded = try JSONDecoder().decode(TextSearchResponse.self, from: data)
        return decoded.results.first?.photos?.first?.photo_reference
    }
}

private struct TextSearchResponse: Decodable {
    struct Result: Decodable {
        struct Photo: Decodable {
            let photo_reference: String
        }
        let photos: [Photo]?
    }
    let results: [Result]
}
