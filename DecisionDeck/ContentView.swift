import SwiftUI
import UIKit

/// Text field styled for high contrast against the animated gradient background, with a lively focus glow.
struct VividTextField: View {
    let placeholder: String
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.black.opacity(0.4)))
            .focused($isFocused)
            .textFieldStyle(.plain)
            .foregroundColor(.black)
            .tint(.indigo)
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isFocused ? Color.yellow : Color.white.opacity(0.9), lineWidth: isFocused ? 3 : 1.5)
            )
            .shadow(color: isFocused ? .yellow.opacity(0.5) : .black.opacity(0.15), radius: isFocused ? 10 : 4)
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isFocused)
    }
}

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
    @FocusState private var promptFocused: Bool
    @FocusState private var constraintsFocused: Bool

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
                    VividTextField(placeholder: "Example: Kuala Lumpur from Sydney, 3 days, food and skyline",
                                   text: $store.prompt,
                                   isFocused: $promptFocused)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Constraints")
                        .font(.headline)
                        .foregroundStyle(.white)
                    VividTextField(placeholder: "Budget, travel time, weather, family friendly",
                                   text: $store.constraints,
                                   isFocused: $constraintsFocused)
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
                Text("\(session.kept.count) kept · \(session.maybe.count) maybe")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            if let option = session.currentOption {
                VStack(spacing: 18) {
                    PlaceCard(option: option)

                    HStack(spacing: 10) {
                        Button {
                            store.makeChoice(.discard)
                        } label: {
                            Label("No", systemImage: "xmark")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.14))
                                .foregroundStyle(.red)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }

                        Button {
                            store.makeChoice(.maybe)
                        } label: {
                            Label("Maybe", systemImage: "questionmark")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange.opacity(0.16))
                                .foregroundStyle(.orange)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }

                        Button {
                            store.makeChoice(.keep)
                        } label: {
                            Label("Yes", systemImage: "checkmark")
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
            ShortlistView(kept: session.kept, maybe: session.maybe)
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
                if let localTitle = option.localTitle {
                    Text(localTitle)
                        .font(.title3.bold())
                        .foregroundStyle(.white.opacity(0.85))
                }
                Text(option.subtitle)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))
                Text(option.description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.93))
                    .lineLimit(4, reservesSpace: true)
                if let localDescription = option.localDescription {
                    Text(localDescription)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(3, reservesSpace: true)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, minHeight: 380)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

/// Wraps UIActivityViewController so the shortlist can be shared to Mail, WhatsApp, Messages, etc.
struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// The printable/exportable layout used both on-screen and when rendered to an image or PDF.
struct ShortlistExportView: View {
    let kept: [DecisionOption]
    let maybe: [DecisionOption]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("DecisionDeck Shortlist")
                .font(.title.bold())

            if !kept.isEmpty {
                shortlistSection(title: "Kept", options: kept, color: .green)
            }
            if !maybe.isEmpty {
                shortlistSection(title: "Maybe", options: maybe, color: .orange)
            }
            if kept.isEmpty && maybe.isEmpty {
                Text("Keep some places to build your shortlist.")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .background(Color.white)
    }

    private func shortlistSection(title: String, options: [DecisionOption], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(color)
            ForEach(options) { option in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(option.title)
                            .font(.headline)
                        if let localTitle = option.localTitle {
                            Text(localTitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text(option.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct ShortlistView: View {
    let kept: [DecisionOption]
    let maybe: [DecisionOption]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale
    @State private var shareItems: [Any]?
    @State private var savedMessage: String?

    var body: some View {
        NavigationStack {
            List {
                if !kept.isEmpty {
                    Section("Kept") {
                        rows(for: kept)
                    }
                }
                if !maybe.isEmpty {
                    Section("Maybe") {
                        rows(for: maybe)
                    }
                }
                if kept.isEmpty && maybe.isEmpty {
                    Text("Keep some places to build your shortlist.")
                        .foregroundStyle(.secondary)
                }
                if let savedMessage {
                    Text(savedMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Shortlist")
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        saveImageToPhotos()
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .disabled(kept.isEmpty && maybe.isEmpty)

                    Button {
                        shareAsPDF()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(kept.isEmpty && maybe.isEmpty)
                }
            }
            .sheet(item: Binding(
                get: { shareItems.map(ShareItemsBox.init) },
                set: { shareItems = $0?.items }
            )) { box in
                ActivityShareSheet(items: box.items)
            }
            #endif
        }
    }

    private func rows(for options: [DecisionOption]) -> some View {
        ForEach(options) { option in
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(option.title)
                        .font(.headline)
                    if let localTitle = option.localTitle {
                        Text(localTitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(option.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @MainActor
    private func renderedImage() -> UIImage? {
        let renderer = ImageRenderer(content: ShortlistExportView(kept: kept, maybe: maybe))
        renderer.scale = displayScale
        return renderer.uiImage
    }

    @MainActor
    private func saveImageToPhotos() {
        guard let image = renderedImage() else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        savedMessage = "Saved to Photos."
    }

    @MainActor
    private func shareAsPDF() {
        let renderer = ImageRenderer(content: ShortlistExportView(kept: kept, maybe: maybe))
        renderer.scale = displayScale
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("DecisionDeck-Shortlist.pdf")
        renderer.render { size, context in
            var box = CGRect(origin: .zero, size: size)
            guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            pdf.beginPDFPage(nil)
            context(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
        }
        shareItems = [url]
    }
}

private struct ShareItemsBox: Identifiable {
    let id = UUID()
    let items: [Any]
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
