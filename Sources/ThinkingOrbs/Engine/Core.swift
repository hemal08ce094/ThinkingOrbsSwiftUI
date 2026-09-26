// Shared primitives for the dotted 3D thought-orbs — a line-for-line port of
// thinking-orbs' src/engine/core.ts. Honestly 3D: rotated, depth-shaded,
// z-sorted. Depth is carried by dot size and ink weight alone.
//
// Every function here is pure math over Double, so the output can be compared
// number-for-number against the web engine (Tests/ThinkingOrbsTests).

import Foundation

/// One circle to draw. Coordinates are in points inside a `size`×`size` box.
public struct OrbDot: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var z: Double
    public var r: Double
    /// Ink value: 0 = darkest ink on paper. Mirrored on dark themes.
    public var white: Double
    public var a: Double

    public init(x: Double, y: Double, z: Double, r: Double, white: Double, a: Double = 1) {
        self.x = x; self.y = y; self.z = z; self.r = r; self.white = white; self.a = a
    }
}

/// A stroked edge between two projected points (the `connecting` web).
public struct OrbLine: Equatable, Sendable {
    public var x1: Double
    public var y1: Double
    public var x2: Double
    public var y2: Double
    /// Ink value, same convention as `OrbDot.white`.
    public var white: Double
    public var a: Double
    public var w: Double
}

/// One rendered instant: a finished draw list. `dots` are already z-sorted
/// into draw order and radius-clamped; `lines` are drawn first.
public struct OrbFrame: Equatable, Sendable {
    public var dots: [OrbDot]
    public var lines: [OrbLine]
}

typealias Projector = (Double, Double, Double) -> (Double, Double, Double)

@inline(__always) func lerp(_ a: Double, _ b: Double, _ f: Double) -> Double { a + (b - a) * f }

@inline(__always) func frac(_ x: Double) -> Double { x - floor(x) }

/// JavaScript's `Math.round`: halves round toward +∞.
@inline(__always) func jsRound(_ x: Double) -> Double { floor(x + 0.5) }

/// JavaScript's `%` for doubles (sign follows the dividend).
@inline(__always) func jsMod(_ a: Double, _ b: Double) -> Double { a.truncatingRemainder(dividingBy: b) }

/// V8's `Math.hypot` (Kahan-compensated, not correctly rounded) — ported so
/// arc lengths in the morph resampler match the web to the last bit.
func jsHypot(_ a: Double, _ b: Double) -> Double {
    let m = max(abs(a), abs(b))
    if m == 0 { return 0 }
    var sum = 0.0, compensation = 0.0
    for v in [a, b] {
        let r = v / m
        let summand = r * r - compensation
        let preliminary = sum + summand
        compensation = (preliminary - sum) - summand
        sum = preliminary
    }
    return sum.squareRoot() * m
}

/// Deterministic hash in [0, 1).
@inline(__always) func hashD(_ a: Double, _ b: Double) -> Double {
    let h = sin(a * 12.9898 + b * 78.233) * 43758.5453
    return h - floor(h)
}

/// Value noise on a 2D lattice — smooth, deterministic, cheap.
func vnoise(_ x: Double, _ y: Double) -> Double {
    let xi = floor(x)
    let yi = floor(y)
    var fx = x - xi
    var fy = y - yi
    fx = fx * fx * (3 - 2 * fx)
    fy = fy * fy * (3 - 2 * fy)
    let a = hashD(xi, yi)
    let b = hashD(xi + 1, yi)
    let c = hashD(xi, yi + 1)
    let d = hashD(xi + 1, yi + 1)
    return a + (b - a) * fx + (c - a) * fy + (a - b - c + d) * fx * fy
}

/// Stable directions on a unit sphere (Fibonacci lattice).
func fibDir(_ i: Int, _ n: Int) -> (Double, Double, Double) {
    let golden = Double.pi * (3 - 5.0.squareRoot())
    let y = 1 - (2 * (Double(i) + 0.5)) / Double(n)
    let rad = (1 - y * y).squareRoot()
    let a = Double(i) * golden
    return (rad * cos(a), y, rad * sin(a))
}

/// Shortest signed angular distance, wrapped to (-π, π].
@inline(__always) func angleDelta(_ a: Double, _ b: Double) -> Double {
    atan2(sin(a - b), cos(a - b))
}

/// Shared spin + tilt + orthographic projection.
func makeProj(_ yaw: Double, _ tilt: Double, _ cx: Double, _ cy: Double, _ scale: Double) -> Projector {
    let st = sin(tilt)
    let ct = cos(tilt)
    let sy = sin(yaw)
    let cyw = cos(yaw)
    return { x, y, z in
        let x1 = x * cyw + z * sy
        let z1 = -x * sy + z * cyw
        let y1 = y * ct - z1 * st
        let z2 = y * st + z1 * ct
        return (cx + x1 * scale, cy - y1 * scale, z2)
    }
}

/// Drop invisible marks, clamp radii to the mode floor, z-sort far→near.
/// The sort is stable (ties keep insertion order), matching V8's `Array.sort`.
func finalizeFrame(_ dots: [OrbDot], _ lines: [OrbLine], _ rMin: Double = 0.3) -> OrbFrame {
    var visible: [(Int, OrbDot)] = []
    visible.reserveCapacity(dots.count)
    for (i, var d) in dots.enumerated() where d.a >= 0.02 {
        d.r = max(rMin, d.r)
        visible.append((i, d))
    }
    visible.sort { $0.1.z != $1.1.z ? $0.1.z < $1.1.z : $0.0 < $1.0 }
    return OrbFrame(dots: visible.map(\.1), lines: lines.filter { $0.a >= 0.02 })
}

/// Dot radii were tuned for a 300pt frame; sub-linear scaling keeps small
/// spinners legible. Lower pow = radii shrink less with size.
@inline(__always) func radiusScale(_ size: Double, _ pow: Double) -> Double {
    Foundation.pow(size / 300, pow)
}
