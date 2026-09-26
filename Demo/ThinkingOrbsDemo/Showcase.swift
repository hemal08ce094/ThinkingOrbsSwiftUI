import SwiftUI
import ThinkingOrbs

/// Sample screens showing the orbs in realistic AI UIs. Launch with
/// `-screen chat|voice|agent|hero` (used for the README screenshots).
enum ShowcaseScreen: String {
    case chat, voice, agent, hero
}

struct ShowcaseRouter: View {
    let screen: ShowcaseScreen

    var body: some View {
        switch screen {
        case .chat: ChatScreen()
        case .voice: VoiceScreen()
        case .agent: AgentScreen()
        case .hero: HeroGrid()
        }
    }
}

// MARK: - AI chat

struct ChatScreen: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    UserBubble("Find me three cosy cafés near Shoreditch that are open late and good for working.")
                    StatusRow(state: .searching, text: "Searching the web…")
                    AssistantBubble {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Here are three that stay open past 10pm:")
                            Text("**1. Ozone Coffee** — big tables, fast Wi-Fi")
                            Text("**2. Allpress Roastery** — quiet upstairs room")
                            Text("**3. Brick Lane Beigel Bake** — open 24/7")
                        }
                    }
                    UserBubble("Which one has the best oat flat white?")
                    HStack(alignment: .top, spacing: 10) {
                        ThinkingOrb(.composing, size: .small)
                            .padding(8)
                            .background(Surface.panel, in: Circle())
                        VStack(alignment: .leading, spacing: 6) {
                            ShimmerText("Composing a reply…")
                            Text("Comparing 214 reviews")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(16)
            }
            .safeAreaInset(edge: .bottom) { Composer() }
            .background(Surface.page)
            .navigationTitle("Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ThinkingOrb(.breathing, size: .small, renderSize: 26)
                }
            }
        }
    }
}

private struct UserBubble: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 18))
            .foregroundStyle(.white)
            .frame(maxWidth: 300, alignment: .trailing)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

private struct AssistantBubble<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Surface.pill, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Surface.stroke))
            .frame(maxWidth: 320, alignment: .leading)
    }
}

private struct StatusRow: View {
    let state: OrbState
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            ThinkingOrb(state, size: .small)
            ShimmerText(text)
        }
        .padding(.leading, 10)
        .padding(.trailing, 14)
        .frame(height: 36)
        .background(Surface.pill, in: Capsule())
        .overlay(Capsule().strokeBorder(Surface.stroke))
    }
}

private struct Composer: View {
    var body: some View {
        HStack(spacing: 10) {
            Text("Ask anything")
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "mic")
                .foregroundStyle(.secondary)
            Image(systemName: "stop.circle.fill")
                .font(.title2)
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Surface.pill, in: Capsule())
        .overlay(Capsule().strokeBorder(Surface.stroke))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

// MARK: - Voice mode

struct VoiceScreen: View {
    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            ThinkingOrb(.listening, theme: .dark, renderSize: 220)
            VStack(spacing: 10) {
                Text("Listening")
                    .font(.title2.weight(.semibold))
                Text("“Remind me to call Sam when I get home, and add oat milk to the shopping list…”")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 32)
            }
            Spacer()
            HStack(spacing: 40) {
                RoundButton(symbol: "mic.slash")
                RoundButton(symbol: "xmark", filled: true)
            }
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .foregroundStyle(.white)
        .environment(\.colorScheme, .dark)
    }
}

private struct RoundButton: View {
    let symbol: String
    var filled = false

    var body: some View {
        Image(systemName: symbol)
            .font(.title2)
            .frame(width: 64, height: 64)
            .background(filled ? Color.white.opacity(0.18) : Color.white.opacity(0.08), in: Circle())
    }
}

// MARK: - Agent task list

struct AgentScreen: View {
    private let steps: [(OrbState?, String, String)] = [
        (nil, "Read the issue", "#482 · Crash when exporting PDF"),
        (nil, "Cloned repository", "acme/reader · 1,204 files"),
        (.searching, "Searching the codebase", "PDFExporter, RenderQueue…"),
        (.solving, "Reasoning about the fix", "Race between render and close"),
        (.weaving, "Merging changes", "3 files"),
        (.composing, "Writing the pull request", "Draft"),
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        ThinkingOrb(.working)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Fixing issue #482").font(.headline)
                            Text("Agent is working · 2m 14s").font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }
                Section("Steps") {
                    ForEach(steps, id: \.1) { state, title, detail in
                        HStack(spacing: 12) {
                            Group {
                                if let state {
                                    ThinkingOrb(state, size: .small)
                                } else {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                }
                            }
                            .frame(width: 22)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(title)
                                Text(detail).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section("Integrations") {
                    HStack(spacing: 12) {
                        ThinkingOrb(.connecting, size: .small).frame(width: 22)
                        Text("Connecting to GitHub…")
                    }
                    HStack(spacing: 12) {
                        ThinkingOrb(.shaping, size: .small).frame(width: 22)
                        Text("Generating diagram…")
                    }
                }
            }
            .navigationTitle("Agent")
        }
    }
}

// MARK: - Hero grid (README header / social preview)

struct HeroGrid: View {
    var body: some View {
        VStack(spacing: 22) {
            Text("Thinking Orbs")
                .font(.system(size: 34, weight: .semibold))
            Text("AI thinking & loading indicators for SwiftUI")
                .foregroundStyle(.secondary)
            Grid(horizontalSpacing: 18, verticalSpacing: 18) {
                ForEach(0..<3) { row in
                    GridRow {
                        ForEach(0..<3) { col in
                            let state = OrbState.allCases[row * 3 + col]
                            VStack(spacing: 8) {
                                ThinkingOrb(state, renderSize: 92)
                                Text(state.rawValue).font(.caption).foregroundStyle(.secondary)
                            }
                            .frame(width: 104)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Surface.page.ignoresSafeArea())
    }
}
