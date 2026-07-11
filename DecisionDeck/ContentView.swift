import SwiftUI

/// Slowly-morphing colorful gradient, like Gemini's ambient background. Intensifies while `isBusy` is true.
struct AnimatedGradientBackground: View {
    var isBusy: Bool = false

    private let palettes: [[Color]] = [
        [Color(red: 0.42, green: 0.35, blue: 0.95), Color(red: 0.98, green: 0.45, blue: 0.62), Color(red: 0.31, green: 0.73, blue: 0.96)],
        [Color(red: 0.98, green: 0.55, blue: 0.32), Color(red: 0.55, green: 0.32, blue: 0.94), Color(red: 0.31, green: 0.85, blue: 0.72)],
        [Color(red: 0.31, green: 0.61, blue: 0.98), Color(red: 0.85, green: 0.36, blue: 0.86), Color(red: 0.98, green: 0.72, blue: 0.34)],
        [Color(red: 0.36, green: 0.85, blue: 0.62), Color(red: 0.35, green: 0.42, blue: 0.95), Color(red: 0.95, green: 0.45, blue: 0.45)],
    ]

    @State private var paletteIndex = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: isBusy ? 1 / 30 : 1 / 12)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let speed = isBusy ? 0.35 : 0.12
            let angle = Angle(degrees: t * speed * 40)

            LinearGradient(
                colors: palettes[paletteIndex],
                startPoint: UnitPoint(x: 0.5 + 0.5 * cos(angle.radians), y: 0.5 + 0.5 * sin(angle.radians)),
                endPoint: UnitPoint(x: 0.5 - 0.5 * cos(angle.radians), y: 0.5 - 0.5 * sin(angle.radians))
            )
            .hueRotation(.degrees(isBusy ? sin(t * 0.6) * 20 : sin(t * 0.15) * 8))
            .saturation(0.9)
            .ignoresSafeArea()
        }
        .onAppear { schedulePaletteCycle() }
    }

    private func schedulePaletteCycle() {
        let interval = isBusy ? 3.5 : 7.0
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            withAnimation(.easeInOut(duration: 2.5)) {
                paletteIndex = (paletteIndex + 1) % palettes.count
            }
            schedulePaletteCycle()
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.accentColor)
                Text("DecisionDeck")
                    .font(.title2.bold())
                VStack(spacing: 6) {
                    Text("Todd Zhang")
                        .font(.headline)
                    Text("phray.zhang@gmail.com")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Link("hdeazy.com", destination: URL(string: "https://www.hdeazy.com/")!)
                        .font(.subheadline)
                }
                Spacer()
            }
            .padding(.top, 40)
            .padding()
            .navigationTitle("About")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            #endif
        }
    }
}

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
    @State private var showAbout = false

    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("DecisionDeck")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                    Text("Turn vague choices into a calm, guided shortlist.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(.top, 12)

                VStack(alignment: .leading, spacing: 8) {
                    Text("What are you deciding?")
                        .font(.headline)
                        .foregroundStyle(.white)
                    TextField("Example: Kuala Lumpur from Sydney, 3 days, food and skyline", text: $store.prompt)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(.white.opacity(0.92))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Constraints")
                        .font(.headline)
                        .foregroundStyle(.white)
                    TextField("Budget, travel time, weather, family friendly", text: $store.constraints)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(.white.opacity(0.92))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Button {
                    store.startSession()
                } label: {
                    Label("Start decision flow", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.white.opacity(0.95))
                        .foregroundStyle(.black)
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
                        .foregroundStyle(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(.white.opacity(0.6), lineWidth: 1)
                        )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("How it works")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("1. Add your decision context.\n2. Review each option as a card.\n3. Keep the ones that feel right and discard the rest.\n4. Finish with a focused shortlist.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }

                Button {
                    showAbout = true
                } label: {
                    Text("About")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.75))
                        .underline()
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            }
            .padding()
            }
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
    }
}

struct DecisionCardView: View {
    let session: DecisionSession
    @ObservedObject var store: DecisionSessionStore
    @State private var showShortlist = false

    var body: some View {
        ZStack {
            if session.currentOption == nil {
                AnimatedGradientBackground(isBusy: true)
            }

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
