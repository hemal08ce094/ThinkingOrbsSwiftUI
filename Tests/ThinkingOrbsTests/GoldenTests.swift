// Golden-vector parity: every dot and line the Swift engine produces must
// match the web engine (thinking-orbs on npm) within 1e-4, for all 9 states ×
// 2 sizes × 4 timestamps. Regenerate golden.json with scripts/extract-golden.mjs.

import XCTest
@testable import ThinkingOrbs

final class GoldenTests: XCTestCase {
    struct Golden: Decodable {
        struct Resolved: Decodable {
            let mode: String
            let speed: Double
            let opts: [String: Double]
        }
        struct Case: Decodable {
            let key: String
            let state: String
            let size: Int
            let t: Double
            let dots: [Double]
            let lines: [Double]
        }
        let tolerance: Double
        let resolved: [String: Resolved]
        let cases: [Case]
    }

    static let golden: Golden = {
        let url = Bundle.module.url(forResource: "golden", withExtension: "json")!
        return try! JSONDecoder().decode(Golden.self, from: Data(contentsOf: url))
    }()

    func testPresetsResolveLikeTheWeb() {
        for (key, want) in Self.golden.resolved {
            let parts = key.split(separator: "-")
            let got = resolvePreset(OrbState(rawValue: String(parts[0]))!, OrbSize(rawValue: Int(parts[1])!)!)
            XCTAssertEqual(got.mode.rawValue, want.mode, key)
            XCTAssertEqual(got.speed, want.speed, key)
            XCTAssertEqual(Set(got.opts.keys), Set(want.opts.keys), key)
            for (k, v) in want.opts {
                XCTAssertEqual(got.opts[k] ?? .nan, v, accuracy: 1e-9, "\(key).\(k)")
            }
        }
    }

    func testEveryFrameMatchesTheWebEngine() {
        let tol = Self.golden.tolerance
        var checked = 0
        for c in Self.golden.cases {
            let frame = OrbEngine.frame(OrbState(rawValue: c.state)!, size: OrbSize(rawValue: c.size)!, t: c.t)
            XCTAssertEqual(frame.dots.count, c.dots.count / 6, "\(c.key) dot count")
            XCTAssertEqual(frame.lines.count, c.lines.count / 7, "\(c.key) line count")
            guard frame.dots.count == c.dots.count / 6, frame.lines.count == c.lines.count / 7 else { continue }
            var worst = 0.0
            let want = stride(from: 0, to: c.dots.count, by: 6).map { Array(c.dots[$0..<$0 + 6]) }
            let got = frame.dots.map { [$0.x, $0.y, $0.z, $0.r, $0.white, $0.a] }
            // Dots at exactly equal depth (the face-on ring's middle lane sits
            // at z = 0) have no defined order: last-ulp libm noise decides it.
            // Compare each run of equal-z dots as a set, everything else in order.
            var i = 0
            while i < want.count {
                var end = i + 1
                while end < want.count, abs(want[end][2] - want[i][2]) <= tol { end += 1 }
                for w in want[i..<end] {
                    let best = got[i..<end].map { g in zip(w, g).map { abs($0 - $1) }.max()! }.min()!
                    worst = max(worst, best)
                    checked += 6
                }
                i = end
            }
            for (i, l) in frame.lines.enumerated() {
                for (j, v) in [l.x1, l.y1, l.x2, l.y2, l.white, l.a, l.w].enumerated() {
                    worst = max(worst, abs(v - c.lines[i * 7 + j]))
                    checked += 1
                }
            }
            XCTAssertLessThanOrEqual(worst, tol, "\(c.key) worst Δ \(worst)")
        }
        XCTAssertGreaterThan(checked, 60_000)
    }
}
