import SwiftUI
import ThinkingOrbs

/// Chat-style status pills: a 20pt orb inline with shimmering text, and a
/// 64pt orb as an assistant avatar.
struct HeroExamples: View {
    var speed: Double

    private let pills: [(OrbState, String)] = [
        (.searching, "Searching the web…"),
        (.solving, "Working through the proof…"),
        (.connecting, "Connecting to GitHub…"),
        (.composing, "Drafting a reply…"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                ThinkingOrb(.listening, size: .large, speed: speed)
                    .background(Surface.panel, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Assistant").font(.subheadline.weight(.semibold))
                    ShimmerText("Listening…")
                }
            }
            FlowLayout(spacing: 8) {
                ForEach(pills, id: \.1) { state, text in
                    HStack(spacing: 8) {
                        ThinkingOrb(state, size: .small, speed: speed)
                        ShimmerText(text)
                    }
                    .padding(.leading, 10)
                    .padding(.trailing, 14)
                    .frame(height: 36)
                    .background(Surface.pill, in: Capsule())
                    .overlay(Capsule().strokeBorder(Surface.stroke))
                }
            }
        }
    }
}

/// Every state at both sizes.
struct Gallery: View {
    var speed: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("States").font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 10)], spacing: 10) {
                ForEach(OrbState.allCases) { state in
                    VStack(spacing: 10) {
                        ThinkingOrb(state, size: .large, speed: speed)
                        HStack(spacing: 6) {
                            ThinkingOrb(state, size: .small, speed: speed)
                            Text(state.rawValue.capitalized).font(.caption)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Surface.panel, in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
}

struct Playground: View {
    @Binding var speed: Double
    @State private var state: OrbState = .listening
    @State private var size: OrbSize = .large
    @State private var paused = false

    private var snippet: String {
        var args = [".\(state.rawValue)", "size: .\(size == .large ? "large" : "small")"]
        if speed != 1 { args.append("speed: \(String(format: "%.2f", speed))") }
        return "ThinkingOrb(\(args.joined(separator: ", ")))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Playground").font(.headline)
            VStack(alignment: .leading, spacing: 14) {
                Label("State", systemImage: "circle.dotted").font(.caption).foregroundStyle(.secondary).labelStyle(.titleOnly)
                FlowLayout(spacing: 8) {
                    ForEach(OrbState.allCases) { s in
                        Chip(title: s.rawValue.capitalized, active: state == s) { state = s }
                    }
                }
                HStack(alignment: .bottom, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Size").font(.caption).foregroundStyle(.secondary)
                        HStack(spacing: 8) {
                            ForEach(OrbSize.allCases) { s in
                                Chip(title: "\(s.rawValue)pt", active: size == s) { size = s }
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Speed \(String(format: "%.2f", speed))×").font(.caption).foregroundStyle(.secondary).monospacedDigit()
                        Slider(value: $speed, in: 0.25...3, step: 0.05)
                            .frame(maxWidth: 200)
                            .accessibilityLabel("Animation speed")
                    }
                }
            }
            .padding(16)
            .background(Surface.panel, in: RoundedRectangle(cornerRadius: 10))

            VStack(spacing: 24) {
                ThinkingOrb(state, size: size, speed: speed, paused: paused)
                    .id("\(state)-\(size)")
                Button {
                    paused.toggle()
                } label: {
                    Image(systemName: paused ? "play.fill" : "pause.fill")
                        .frame(width: 36, height: 36)
                        .background(Surface.pill, in: Circle())
                        .overlay(Circle().strokeBorder(Surface.stroke))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(paused ? "Play" : "Pause")
            }
            .frame(maxWidth: .infinity, minHeight: 260)
            .background(Surface.panel.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))

            CodeBlock(title: nil, code: snippet)
        }
    }
}

struct Chip: View {
    var title: String
    var active: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.footnote)
                .padding(.horizontal, 12)
                .frame(height: 34)
                .background(active ? Surface.pill : .clear, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(active ? Surface.stroke : .clear))
                .foregroundStyle(active ? .primary : .secondary)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(active ? .isSelected : [])
    }
}

struct CodeBlock: View {
    var title: String?
    var code: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title { Text(title).font(.headline) }
            Text(code)
                .font(.system(.footnote, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Surface.panel, in: RoundedRectangle(cornerRadius: 10))
        }
    }
}

/// The web demo's text shimmer: a bright band sweeping left → right over
/// muted text every 2s.
struct ShimmerText: View {
    var text: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(_ text: String) { self.text = text }

    var body: some View {
        let base = Text(text).font(.subheadline)
        if reduceMotion {
            base.foregroundStyle(.secondary)
        } else {
            TimelineView(.animation) { ctx in
                let p = ctx.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 2) / 2
                base.foregroundStyle(
                    LinearGradient(stops: [
                        .init(color: .secondary, location: 0),
                        .init(color: .primary, location: 0.5),
                        .init(color: .secondary, location: 1),
                    ], startPoint: UnitPoint(x: -1 + 3 * p - 0.5, y: 0), endPoint: UnitPoint(x: -1 + 3 * p + 0.5, y: 0))
                )
            }
        }
    }
}

/// Minimal wrapping HStack.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(proposal.width ?? .infinity, subviews)
        return CGSize(width: rows.map(\.width).max() ?? 0, height: rows.last.map { $0.y + $0.height } ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for row in arrange(bounds.width, subviews) {
            var x = bounds.minX
            for i in row.items {
                let s = subviews[i].sizeThatFits(.unspecified)
                subviews[i].place(at: CGPoint(x: x, y: bounds.minY + row.y + (row.height - s.height) / 2), proposal: .unspecified)
                x += s.width + spacing
            }
        }
    }

    private struct Row { var items: [Int] = []; var y: CGFloat = 0; var width: CGFloat = 0; var height: CGFloat = 0 }

    private func arrange(_ maxWidth: CGFloat, _ subviews: Subviews) -> [Row] {
        var rows = [Row()]
        for (i, v) in subviews.enumerated() {
            let s = v.sizeThatFits(.unspecified)
            if !rows[rows.count - 1].items.isEmpty, rows[rows.count - 1].width + spacing + s.width > maxWidth {
                let last = rows[rows.count - 1]
                rows.append(Row(y: last.y + last.height + spacing))
            }
            let gap = rows[rows.count - 1].items.isEmpty ? 0 : spacing
            rows[rows.count - 1].items.append(i)
            rows[rows.count - 1].width += gap + s.width
            rows[rows.count - 1].height = max(rows[rows.count - 1].height, s.height)
        }
        return rows
    }
}
