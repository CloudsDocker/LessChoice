import Foundation

struct DecisionOption: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let description: String
    let category: String
    var imageURL: URL?
    var localTitle: String?
    var localDescription: String?
}

enum DecisionChoice: String {
    case keep, maybe, discard
}

struct DecisionSession {
    let prompt: String
    let constraints: String
    var options: [DecisionOption]
    var kept: [DecisionOption]
    var maybe: [DecisionOption]
    var discarded: [DecisionOption]
    var currentIndex: Int

    var currentOption: DecisionOption? {
        guard currentIndex < options.count else { return nil }
        return options[currentIndex]
    }

    var isComplete: Bool {
        false
    }
}

@MainActor
final class DecisionSessionStore: ObservableObject {
    @Published var prompt = ""
    @Published var constraints = ""
    @Published var session: DecisionSession?
    @Published var statusMessage = ""
    @Published var isLoadingMore = false

    private let refillThreshold = 2
    private let batchSize = 5
    private var fetchTask: Task<Void, Never>?

    func startSession() {
        let normalizedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedConstraints = constraints.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalPrompt = normalizedPrompt.isEmpty ? "Kuala Lumpur from Sydney" : normalizedPrompt
        let finalConstraints = normalizedConstraints.isEmpty ? "Weekend trip, budget-friendly, must be easy" : normalizedConstraints

        session = DecisionSession(prompt: finalPrompt,
                                  constraints: finalConstraints,
                                  options: [],
                                  kept: [],
                                  maybe: [],
                                  discarded: [],
                                  currentIndex: 0)
        statusMessage = "Finding options for you..."
        loadMore()
    }

    func makeChoice(_ choice: DecisionChoice) {
        guard var currentSession = session else { return }

        if let currentOption = currentSession.currentOption {
            switch choice {
            case .keep:
                currentSession.kept.append(currentOption)
            case .maybe:
                currentSession.maybe.append(currentOption)
            case .discard:
                currentSession.discarded.append(currentOption)
            }
        }

        currentSession.currentIndex += 1
        session = currentSession
        switch choice {
        case .keep:
            statusMessage = "Kept. Finding more like this."
        case .maybe:
            statusMessage = "Saved as maybe. Still deciding."
        case .discard:
            statusMessage = "Removed. Steering away from that."
        }

        if currentSession.options.count - currentSession.currentIndex <= refillThreshold {
            loadMore()
        }
    }

    func reset() {
        fetchTask?.cancel()
        session = nil
        prompt = ""
        constraints = ""
        statusMessage = ""
        isLoadingMore = false
    }

    private func loadMore() {
        guard let currentSession = session, fetchTask == nil else { return }
        isLoadingMore = true

        let likedTitles = currentSession.kept.map(\.title)
        let blacklistedTitles = currentSession.discarded.map(\.title)
        let alreadySuggestedTitles = currentSession.options.map(\.title)
        let placeContext = currentSession.prompt

        fetchTask = Task { [weak self] in
            guard let self else { return }
            defer {
                self.fetchTask = nil
                self.isLoadingMore = false
            }

            do {
                let suggestions = try await GeminiService.fetchPlaces(
                    prompt: currentSession.prompt,
                    constraints: currentSession.constraints,
                    likedTitles: likedTitles,
                    blacklistedTitles: blacklistedTitles,
                    alreadySuggestedTitles: alreadySuggestedTitles,
                    count: self.batchSize
                )

                var newOptions: [DecisionOption] = []
                for suggestion in suggestions {
                    let imageURL = await PlacesService.photoURL(forPlace: suggestion.title, context: placeContext)
                    newOptions.append(DecisionOption(title: suggestion.title,
                                                      subtitle: suggestion.subtitle,
                                                      description: suggestion.description,
                                                      category: suggestion.category,
                                                      imageURL: imageURL,
                                                      localTitle: suggestion.localTitle?.isEmpty == false ? suggestion.localTitle : nil,
                                                      localDescription: suggestion.localDescription?.isEmpty == false ? suggestion.localDescription : nil))
                }

                guard var updatedSession = self.session else { return }
                updatedSession.options.append(contentsOf: newOptions)
                self.session = updatedSession
                if newOptions.isEmpty {
                    self.statusMessage = "Couldn't find more suggestions right now."
                } else {
                    self.statusMessage = "Keep the options you like and discard the rest."
                }
            } catch {
                self.statusMessage = "Couldn't reach Gemini for more suggestions. Try again."
            }
        }
    }
}
