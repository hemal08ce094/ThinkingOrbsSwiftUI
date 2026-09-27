// The ThinkingOrb view. One shared clock keeps every orb on screen in phase;
// `TimelineView(.animation)` drives the frames and stops by itself when the
// view is off screen. Reduced-motion users get a static representative frame
// that still follows the live colour scheme.

import SwiftUI

/// Shared epoch — the web's `performance.now()`. Every orb reads the same
/// clock, so two orbs of the same state animate in lockstep.
///
/// A file-scope `let` is initialised lazily, on first read, i.e. inside the
/// first orb's `TimelineView` closure: *after* that frame's `context.date`
/// was taken. The very first `t` is therefore a few microseconds negative
/// (the wall clock can also step backwards). Always read time through
/// `orbTime(_:)`, which clamps it to >= 0.
private let orbEpoch = Date()

@inline(__always) private func orbTime(_ date: Date) -> Double {
    max(0, date.timeIntervalSince(orbEpoch))
}

/// A dotted thought-orb loading indicator.
///
/// ```swift
/// ThinkingOrb(.searching)
/// ThinkingOrb(.solving, size: .small)
/// ThinkingOrb(.working, size: 20, theme: .dark, speed: 1.5)
/// ```
public struct ThinkingOrb: View {
    public var state: OrbState
    public var size: OrbSize
    public var theme: OrbTheme
    public var speed: Double
    public var paused: Bool
    public var label: String?
    /// Draw the tuned design at a custom point size (crisp, re-rasterised —
    /// unlike `scaleEffect`). `nil` uses the preset's own 64 / 20pt.
    public var renderSize: CGFloat?

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var frozenAt: Date?

    /// - Parameters:
    ///   - state: which animation to show.
    ///   - size: tuned size preset — 64pt (`.large`) or 20pt (`.small`).
    ///   - theme: `.auto` follows `colorScheme`; `.dark` pins light dots for
    ///     dark backgrounds, `.light` pins dark dots for light backgrounds.
    ///   - speed: multiplier on the preset's baked speed.
    ///   - paused: freeze on the current frame.
    ///   - label: VoiceOver label; defaults to the per-state label ("Searching…").
    ///   - renderSize: draw the chosen design at another point size, e.g. 128
    ///     for a hero or 32 for a toolbar. Dots stay sharp.
    public init(_ state: OrbState = .working, size: OrbSize = .large, theme: OrbTheme = .auto,
                speed: Double = 1, paused: Bool = false, label: String? = nil, renderSize: CGFloat? = nil) {
        self.state = state
        self.size = size
        self.theme = theme
        self.speed = speed
        self.paused = paused
        self.label = label
        self.renderSize = renderSize
    }

    private var dark: Bool {
        switch theme {
        case .dark: true
        case .light: false
        case .auto: colorScheme == .dark
        }
    }

    public var body: some View {
        let resolved = resolvePreset(state, size)
        let effSpeed = resolved.speed * speed
        Group {
            if reduceMotion {
                // one static, deterministic frame — same instant the web uses
                OrbCanvas(state: state, size: size, dark: dark, t: 0.6, renderSize: renderSize)
            } else if paused {
                OrbCanvas(state: state, size: size, dark: dark,
                          t: orbTime(frozenAt ?? Date()) * effSpeed, renderSize: renderSize)
            } else {
                TimelineView(.animation) { context in
                    OrbCanvas(state: state, size: size, dark: dark,
                              t: orbTime(context.date) * effSpeed, renderSize: renderSize)
                }
            }
        }
        .frame(width: renderSize ?? size.points, height: renderSize ?? size.points)
        .accessibilityElement()
        .accessibilityAddTraits(.isImage)
        .accessibilityLabel(Text(label ?? state.label))
        .onAppear { if paused { frozenAt = Date() } }
        .modifier(PauseTracker(paused: paused, frozenAt: $frozenAt))
    }
}

/// Records the moment `paused` flips on, so the orb freezes where it was.
private struct PauseTracker: ViewModifier {
    let paused: Bool
    @Binding var frozenAt: Date?

    func body(content: Content) -> some View {
        if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, visionOS 1, *) {
            content.onChange(of: paused) { _, now in frozenAt = now ? Date() : nil }
        } else {
            content.onChange(of: paused) { now in frozenAt = now ? Date() : nil }
        }
    }
}

/// Draws one frozen instant of an orb. Use this directly for snapshots,
/// widgets or `ImageRenderer`, where you want a specific frame.
///
/// `t` is in preset-clock seconds: wall seconds × the preset's baked speed.
public struct OrbCanvas: View {
    public var state: OrbState
    public var size: OrbSize
    public var dark: Bool
    public var t: Double
    /// Point size to draw at; `nil` uses the preset's own size.
    public var renderSize: CGFloat?

    public init(state: OrbState, size: OrbSize = .large, dark: Bool, t: Double, renderSize: CGFloat? = nil) {
        self.state = state
        self.size = size
        self.dark = dark
        self.t = t
        self.renderSize = renderSize
    }

    public var body: some View {
        let frame = OrbEngine.frame(state, size: size, t: t)
        let side = renderSize ?? size.points
        Canvas { context, canvasSize in
            let k = canvasSize.width / size.points
            if k != 1 { context.scaleBy(x: k, y: k) }
            OrbPainter.paint(frame, dark: dark, in: &context)
        }
        .frame(width: side, height: side)
    }
}

/// The 2D binding: lines first, then dots in z order, matte grayscale.
public enum OrbPainter {
    /// On dark substrates the ink is mirrored (1 - white) so near dots read
    /// bright — the same depth language on an inverted substrate. Quantised to
    /// 8 bits like the web's `rgba(g,g,g,a)`.
    static func ink(_ white: Double, _ alpha: Double, dark: Bool) -> Color {
        let w = min(1, max(0, white))
        let g = jsRound((dark ? 1 - w : w) * 255) / 255
        return Color(.sRGB, red: g, green: g, blue: g, opacity: alpha)
    }

    public static func paint(_ frame: OrbFrame, dark: Bool, in context: inout GraphicsContext) {
        for l in frame.lines {
            var p = Path()
            p.move(to: CGPoint(x: l.x1, y: l.y1))
            p.addLine(to: CGPoint(x: l.x2, y: l.y2))
            context.stroke(p, with: .color(ink(l.white, l.a, dark: dark)), lineWidth: l.w)
        }
        for d in frame.dots {
            let rect = CGRect(x: d.x - d.r, y: d.y - d.r, width: d.r * 2, height: d.r * 2)
            context.fill(Path(ellipseIn: rect), with: .color(ink(d.white, d.a, dark: dark)))
        }
    }
}
