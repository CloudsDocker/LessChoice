import Foundation

private struct PlacePhotoResponse: Decodable {
    let photoUrl: String?
}

enum PlacesService {
    static func photoURL(forPlace title: String, context: String) async -> URL? {
        var components = URLComponents(string: "\(Config.backendBaseURL)/v1/place-photo")!
        components.queryItems = [
            URLQueryItem(name: "title", value: title),
            URLQueryItem(name: "context", value: context)
        ]
        var request = URLRequest(url: components.url!)
        request.setValue(Config.appSharedSecret, forHTTPHeaderField: "x-app-secret")

        guard let (data, response) = try? await BackendClient.dataWithColdStartRetry(for: request),
              let http = response as? HTTPURLResponse, http.statusCode == 200,
              let decoded = try? JSONDecoder().decode(PlacePhotoResponse.self, from: data),
              let photoPath = decoded.photoUrl else {
            return nil
        }

        return URL(string: photoPath, relativeTo: URL(string: Config.backendBaseURL))
    }
}
