// Density profiles, the multiplier machinery that scales them, and the
// shipped tunings — ports of src/engine/profiles.ts and src/presets.ts.
// Nine states × two sizes, each resolved once and cached.

import Foundation

/// Resolved draw options for one mode: a flat bag of named numbers, exactly
/// like the web engine's `ModeOpts`.
public typealias OrbOpts = [String: Double]

/// Engine mode — the geometry family a state draws with.
public enum OrbMode: String, CaseIterable, Sendable {
    case orbits, globe, rubik, wave, web, braid, ribbon, ring, morph
}

// 2-D lattices (rings × dots-per-ring) come in pairs — each side takes
// √scale so the TOTAL dot count scales by `scale`; flat lists scale linearly.
private let countPairs: [(String, String)] = [("latRings", "lonDensity"), ("rings", "lonDensity"), ("lanes", "segs")]
private let countKeys = ["orbitN", "ghostN", "nodeN", "strandN", "signals"]
private let iconDensityKeys = ["iconD"]
private let radiusKeys = ["rBase", "rDepth", "rActive", "rDot", "ghostR", "partR", "partRDepth", "nodeR", "nodeRDepth"]

func scaleCounts(_ opts: OrbOpts, _ scale: Double) -> OrbOpts {
    var out = opts
    var done = Set<String>()
    let rt = scale.squareRoot()
    for (a, b) in countPairs {
        if let va = out[a], let vb = out[b], !done.contains(a), !done.contains(b) {
            out[a] = max(2, jsRound(va * rt))
            out[b] = max(2, jsRound(vb * rt))
            done.insert(a)
            done.insert(b)
        }
    }
    for k in countKeys {
        // 0 means the mode opted out of that layer entirely (ring has no ghost
        // sphere) — scaling must not resurrect it as a single stray dot
        if let v = out[k], v != 0, !done.contains(k) { out[k] = max(1, jsRound(v * scale)) }
    }
    for k in iconDensityKeys {
        if let v = out[k] { out[k] = max(0.02, v * scale) }
    }
    return out
}

func scaleRadii(_ opts: OrbOpts, _ scale: Double) -> OrbOpts {
    var out = opts
    for k in radiusKeys {
        if let v = out[k] { out[k] = v * scale }
    }
    out["rSizeMul"] = (out["rSizeMul"] ?? 1) * scale
    return out
}

/// Base (fine) profiles per mode, before preset multipliers.
let baseProfiles: [OrbMode: OrbOpts] = [
    .globe: ["latRings": 17, "lonDensity": 44, "rBase": 0.6, "rDepth": 1.7, "rBoost": 1.0,
             "inkFar": 0.62, "inkSpan": 0.54, "rsPow": 0.6, "rMin": 0.3],
    .orbits: ["orbitN": 12, "ghostN": 40, "ghostR": 0.9, "ghostA": 0.5, "particles": 3,
              "partR": 1.2, "partRDepth": 1.6, "rsPow": 0.6, "rMin": 0.3],
    .rubik: ["latRings": 15, "lonDensity": 40, "moveCount": 14, "rBase": 0.6, "rDepth": 1.7,
             "rActive": 0.3, "inkFar": 0.62, "inkSpan": 0.54, "rsPow": 0.6, "rMin": 0.3],
    .wave: ["rings": 15, "lonDensity": 40, "rBase": 0.6, "rDepth": 1.7, "rsPow": 0.6, "rMin": 0.3],
    .web: ["nodeN": 30, "thr": 0.72, "signals": 5, "nodeR": 1.4, "nodeRDepth": 1.8, "lineW": 0.8,
           "rsPow": 0.6, "rMin": 0.3],
    .braid: ["strandN": 52, "turns": 3.0, "ghostN": 150, "rBase": 1.2, "rDepth": 1.8, "rsPow": 0.6, "rMin": 0.3],
    .ribbon: ["lanes": 5, "segs": 88, "ghostN": 150, "rBase": 1.1, "rDepth": 1.7, "rsPow": 0.6, "rMin": 0.3],
    // ring shares ribbon's painter; faceOn cancels the camera tilt and moves
    // the undulation onto the radius, and there is no ghost sphere behind it
    .ring: ["lanes": 5, "segs": 88, "ghostN": 0, "faceOn": 1, "rBase": 1.1, "rDepth": 1.7, "rsPow": 0.6, "rMin": 0.3],
    .morph: ["rDot": 0.021, "iconD": 1, "rMin": 0.25],
]

struct Preset {
    var speed: Double
    var count: Double
    var size: Double
    var extra: OrbOpts = [:]
}

/// The shipped tunings, baked from the upstream mini-page tuning session.
func preset(_ mode: OrbMode, _ size: OrbSize) -> Preset {
    let large = size == .large
    switch mode {
    case .orbits:
        return large ? Preset(speed: 1.885, count: 1, size: 1)
            : Preset(speed: 3.9, count: 0.238, size: 2.4)
    case .globe:
        return large ? Preset(speed: 2.015, count: 0.42, size: 1.15, extra: ["scanMul": 4.08, "dimBase": 0.45])
            : Preset(speed: 2.665, count: 0.105, size: 1.75, extra: ["scanMul": 4.335, "dimBase": 0.45])
    case .rubik:
        return large ? Preset(speed: 1.82, count: 0.35, size: 1.05)
            : Preset(speed: 1.95, count: 0.088, size: 1.9)
    case .wave:
        return large ? Preset(speed: 4.388, count: 0.341, size: 1)
            : Preset(speed: 3.998, count: 0.105, size: 1.6)
    case .web:
        return large ? Preset(speed: 3.315, count: 1.35, size: 0.95)
            : Preset(speed: 6.63, count: 0.25, size: 1.52)
    case .braid:
        return large ? Preset(speed: 1.625, count: 0.5, size: 1)
            : Preset(speed: 2.75, count: 0.1125, size: 1.36)
    case .ribbon:
        return large ? Preset(speed: 2.34, count: 0.25, size: 0.85, extra: ["spin": 0, "bandMul": 3.9, "wobMul": 1])
            : Preset(speed: 3.12, count: 0.051, size: 1.073, extra: ["spin": 0, "bandMul": 4.94, "wobMul": 1])
    case .ring:
        return large ? Preset(speed: 3.24, count: 0.25, size: 0.956, extra: ["spin": 0, "bandMul": 3.627, "wobMul": 0.368])
            : Preset(speed: 3.78, count: 0.028, size: 1.622, extra: ["spin": 0, "bandMul": 3.968, "wobMul": 0.565])
    case .morph:
        return large ? Preset(speed: 2.405, count: 0.702, size: 0.395, extra: ["spread": 1.45])
            : Preset(speed: 2.08, count: 0.53, size: 1.011, extra: ["spread": 1.45])
    }
}

/// A (state, size) pair resolved to its mode, baked speed and scaled options.
public struct OrbResolved: Sendable {
    public let mode: OrbMode
    public let speed: Double
    public let opts: OrbOpts
}

private let resolvedCache: [String: OrbResolved] = {
    var out: [String: OrbResolved] = [:]
    for state in OrbState.allCases {
        for size in OrbSize.allCases {
            let mode = state.mode
            let p = preset(mode, size)
            var opts = baseProfiles[mode]!
            if p.count != 1 { opts = scaleCounts(opts, p.count) }
            if p.size != 1 { opts = scaleRadii(opts, p.size) }
            opts.merge(p.extra) { _, new in new }
            out["\(state.rawValue)-\(size.rawValue)"] = OrbResolved(mode: mode, speed: p.speed, opts: opts)
        }
    }
    return out
}()

/// Resolve a (state, size) pair to its mode + fully-scaled draw options.
public func resolvePreset(_ state: OrbState, _ size: OrbSize) -> OrbResolved {
    resolvedCache["\(state.rawValue)-\(size.rawValue)"]!
}
