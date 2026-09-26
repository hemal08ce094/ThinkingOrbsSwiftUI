import Foundation

/// The nine shipped states — each a hand-tuned animation.
public enum OrbState: String, CaseIterable, Identifiable, Sendable {
    /// Particles on tilted orbits.
    case working
    /// A scan meridian sweeps a dotted globe.
    case searching
    /// Bands scramble in quarter turns, then click back solved.
    case solving
    /// A waveform rolls through latitude rings.
    case listening
    /// A constellation wires itself, packets running the edges.
    case connecting
    /// Three strands plait around the sphere.
    case weaving
    /// An undulating multi-band sash.
    case composing
    /// A face-on ring slowly morphing.
    case breathing
    /// A dotted outline morphs circle → triangle → square.
    case shaping

    public var id: String { rawValue }

    /// The engine mode that draws this state.
    public var mode: OrbMode {
        switch self {
        case .working: .orbits
        case .searching: .globe
        case .solving: .rubik
        case .listening: .wave
        case .connecting: .web
        case .weaving: .braid
        case .composing: .ribbon
        case .breathing: .ring
        case .shaping: .morph
        }
    }

    /// Default VoiceOver label, same strings as the web component.
    public var label: String {
        switch self {
        case .working: "Working…"
        case .searching: "Searching…"
        case .solving: "Solving…"
        case .listening: "Listening…"
        case .connecting: "Connecting…"
        case .weaving: "Weaving…"
        case .composing: "Composing…"
        case .breathing: "Thinking…"
        case .shaping: "Shaping…"
        }
    }
}

/// Rendered size in points. Exactly two tuned presets ship — separate
/// designs, not a scale factor. Integer literals work: `size: 20`.
public enum OrbSize: Int, CaseIterable, Identifiable, Sendable, ExpressibleByIntegerLiteral {
    /// 64pt — chat-avatar scale.
    case large = 64
    /// 20pt — inline-text scale.
    case small = 20

    public var id: Int { rawValue }
    public var points: CGFloat { CGFloat(rawValue) }

    /// Any literal ≤ 42 picks the 20pt design, anything larger the 64pt one.
    public init(integerLiteral value: Int) {
        self = value <= 42 ? .small : .large
    }
}

/// Theme mode. `auto` follows the SwiftUI `colorScheme` environment.
/// Dark renders light ink (for dark backgrounds); light renders dark ink.
public enum OrbTheme: String, CaseIterable, Sendable {
    case auto, dark, light
}
