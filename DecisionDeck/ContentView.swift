import SwiftUI

struct ContentView: View {
    @StateObject private var store = DecisionSessionStore()

    var body: some View {
        NavigationStack {
            if let session = store.session {
                DecisionCardView(session: session, store: store)
            } else {
                SetupView(store: store)
            }
        }
    }
}

struct SetupView: View {
    @ObservedObject var store: DecisionSessionStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("DecisionDeck")
                        .font(.largeTitle.bold())
                    Text("Turn vague choices into a calm, guided shortlist.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("What are you deciding?")
                        .font(.headline)
                    TextField("Example: Kuala Lumpur from Sydney, 3 days, food and skyline", text: $store.prompt)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Constraints")
                        .font(.headline)
                    TextField("Budget, travel time, weather, family friendly", text: $store.constraints)
                        .textFieldStyle(.roundedBorder)
                }

                Button {
                    store.startSession()
                } label: {
                    Label("Start decision flow", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                Button {
                    store.prompt = "Kuala Lumpur from Sydney"
                    store.constraints = "Weekend trip, budget-friendly, easy to reach"
                    store.startSession()
                } label: {
                    Label("Load sample trip idea", systemImage: "airplane")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("How it works")
                        .font(.headline)
                    Text("1. Add your decision context.\n2. Review each option as a card.\n3. Keep the ones that feel right and discard the rest.\n4. Finish with a focused shortlist.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("DecisionDeck")
    }
}

struct DecisionCardView: View {
    let session: DecisionSession
    @ObservedObject var store: DecisionSessionStore
    @State private var showShortlist = false

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.prompt)
                        .font(.headline)
                    Text(session.constraints)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(session.kept.count) kept")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            if let option = session.currentOption {
                VStack(spacing: 18) {
                    PlaceCard(option: option)

                    HStack(spacing: 14) {
                        Button {
                            store.makeChoice(.discard)
                        } label: {
                            Label("Discard", systemImage: "xmark")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.14))
                                .foregroundStyle(.red)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }

                        Button {
                            store.makeChoice(.keep)
                        } label: {
                            Label("Keep", systemImage: "checkmark")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green.opacity(0.16))
                                .foregroundStyle(.green)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Finding more places for you...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(minHeight: 320)
            }

            Text(store.statusMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .navigationTitle("Decision flow")
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Shortlist") {
                    showShortlist = true
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Reset") {
                    store.reset()
                }
            }
            #endif
        }
        .sheet(isPresented: $showShortlist) {
            ShortlistView(kept: session.kept)
        }
    }
}

struct PlaceCard: View {
    let option: DecisionOption

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(colors: [.indigo, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
            if let imageURL = option.imageURL {
                GeometryReader { geometry in
                    AsyncImage(url: imageURL) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()
                        } else {
                            Color.clear
                        }
                    }
                }
            }
            LinearGradient(colors: [.black.opacity(0.55), .clear, .black.opacity(0.35)],
                           startPoint: .bottom, endPoint: .center)
            VStack(alignment: .leading, spacing: 12) {
                Spacer()
                Text(option.category)
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.22))
                    .clipShape(Capsule())
                Text(option.title)
                    .font(.title.bold())
                    .foregroundStyle(.white)
                Text(option.subtitle)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))
                Text(option.description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.93))
                    .lineLimit(4, reservesSpace: true)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, minHeight: 380)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct ShortlistView: View {
    let kept: [DecisionOption]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if kept.isEmpty {
                    Text("Keep some places to build your shortlist.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(kept) { option in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(option.title)
                                .font(.headline)
                            Text(option.description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Shortlist")
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            #endif
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
