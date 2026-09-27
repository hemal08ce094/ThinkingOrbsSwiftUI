// The nine mode painters as pure geometry — ports of src/engine/{orbits,
// lattice,web,braid,ribbon,morph}.ts. Each takes (size, t, opts) and returns
// a finished, z-sorted frame. Formulas are transcribed verbatim; the golden
// tests pin every dot to the web engine's output.

import Foundation

public enum OrbEngine {
    /// Geometry for one instant of `mode` in a `size`×`size` box.
    public static func frame(_ mode: OrbMode, size: Double, t: Double, opts: OrbOpts) -> OrbFrame {
        switch mode {
        case .orbits: orbits(size, t, opts)
        case .globe: globe(size, t, opts)
        case .rubik: rubik(size, t, opts)
        case .wave: wave(size, t, opts)
        case .web: web(size, t, opts)
        case .braid: braid(size, t, opts)
        // ring shares ribbon's geometry — the `faceOn` profile flag switches it
        case .ribbon, .ring: ribbon(size, t, opts)
        case .morph: morph(size, t, opts)
        }
    }

    /// Geometry for a state at its tuned size. `t` is preset-clock seconds
    /// (wall seconds × the preset's baked speed × any user speed).
    public static func frame(_ state: OrbState, size: OrbSize, t: Double) -> OrbFrame {
        let r = resolvePreset(state, size)
        return frame(r.mode, size: Double(size.rawValue), t: t, opts: r.opts)
    }

    // MARK: - Orbits — working

    static func orbits(_ size: Double, _ t: Double, _ o: OrbOpts) -> OrbFrame {
        let cx = size / 2, cy = size / 2
        let R = (size / 2) * 0.82
        let pt = makeProj(t * 0.12, 0.3, cx, cy, 1)
        let rs = radiusScale(size, o["rsPow"] ?? 0.6)
        let orbitN = Int(o["orbitN"] ?? 12)
        let ghostN = Int(o["ghostN"] ?? 40)
        let particles = Int(o["particles"] ?? 3)
        let ghostR = o["ghostR"] ?? 0.9, ghostA = o["ghostA"] ?? 0.5
        let partR = o["partR"] ?? 1.2, partRDepth = o["partRDepth"] ?? 1.6

        var dots: [OrbDot] = []
        for orb in 0..<orbitN {
            let h1 = hashD(Double(orb), 1.7)
            let h2 = hashD(Double(orb), 5.2)
            let h3 = hashD(Double(orb), 8.9)
            let ro = R * (0.45 + 0.52 * h1)
            let th = h1 * 2 * .pi
            let phi = acos(2 * h2 - 1)
            let nx = sin(phi) * cos(th)
            let ny = cos(phi)
            let nz = sin(phi) * sin(th)
            var ux = -ny
            var uy = nx
            let uz = 0.0
            let ul = max(1e-6, (ux * ux + uy * uy).squareRoot())
            ux /= ul
            uy /= ul
            let vx = ny * uz - nz * uy
            let vy = nz * ux - nx * uz
            let vz = nx * uy - ny * ux
            let speed = (0.25 + 0.55 * h3) * (h3 > 0.5 ? 1 : -1)

            for k in 0..<ghostN {
                let a = (Double(k) / Double(ghostN)) * 2 * .pi
                let (px, py, z) = pt((ux * cos(a) + vx * sin(a)) * ro,
                                     (uy * cos(a) + vy * sin(a)) * ro,
                                     (uz * cos(a) + vz * sin(a)) * ro)
                let depth = (z / ro + 1) / 2
                dots.append(OrbDot(x: px, y: py, z: z, r: ghostR * rs, white: 0.72, a: ghostA * (0.4 + 0.6 * depth)))
            }
            for m in 0..<particles {
                let a = t * speed + (Double(m) / Double(particles)) * 2 * .pi + h2 * 6
                let (px, py, z) = pt((ux * cos(a) + vx * sin(a)) * ro,
                                     (uy * cos(a) + vy * sin(a)) * ro,
                                     (uz * cos(a) + vz * sin(a)) * ro)
                let depth = (z / ro + 1) / 2
                dots.append(OrbDot(x: px, y: py, z: z, r: (partR + partRDepth * depth) * rs, white: 0.3 - 0.22 * depth))
            }
        }
        return finalizeFrame(dots, [], o["rMin"] ?? 0.3)
    }

    // MARK: - Globe — searching

    static func globe(_ size: Double, _ t: Double, _ o: OrbOpts) -> OrbFrame {
        let spin = 0.5
        let cx = size / 2, cy = size / 2
        let radius = (size / 2) * 0.82
        let tilt = 0.4 + 0.06 * sin(t * 0.35)
        let pt = makeProj(t * spin, tilt, cx, cy, radius)
        let scan = t * (spin + (1.7 - spin) * (o["scanMul"] ?? 1))
        let rs = radiusScale(size, o["rsPow"] ?? 0.6)
        let dimBase = o["dimBase"] ?? 1
        let rBase = o["rBase"] ?? 0.6, rDepth = o["rDepth"] ?? 1.7, rBoost = o["rBoost"] ?? 1
        let inkFar = o["inkFar"] ?? 0.62, inkSpan = o["inkSpan"] ?? 0.54

        var dots: [OrbDot] = []
        let latRings = Int(o["latRings"] ?? 17)
        let lonDensity = o["lonDensity"] ?? 44
        for li in 0...latRings {
            let lat = -Double.pi / 2 + (Double(li) / Double(latRings)) * .pi
            let cosLat = cos(lat), sinLat = sin(lat)
            let lonCount = max(1, Int(jsRound(abs(cosLat) * lonDensity)))
            for lj in 0..<lonCount {
                let lon = (Double(lj) / Double(lonCount)) * 2 * .pi
                let (px, py, z) = pt(cosLat * cos(lon), sinLat, cosLat * sin(lon))
                let depth = (z + 1) / 2
                let d = angleDelta(lon + t * spin, scan)
                let boost = exp(-(d * d) / 0.18) * max(0, z)
                dots.append(OrbDot(x: px, y: py, z: z,
                                   r: (rBase + rDepth * depth + rBoost * boost) * rs,
                                   white: inkFar - inkSpan * depth,
                                   a: dimBase + (1 - dimBase) * min(1, boost)))
            }
        }
        return finalizeFrame(dots, [], o["rMin"] ?? 0.3)
    }

    // MARK: - Rubik — solving

    private struct Move {
        var axis: Int
        var lo: Double
        var hi: Double
        var ang: Double
    }

    private static func solveCycle(_ time: Double, _ count: Int, _ slotDur: Double, _ rest: Double) -> (amount: [Double], active: Int) {
        let cyc = 2 * Double(count) * slotDur + rest
        let tc = jsMod(time, cyc)
        var amount = [Double](repeating: 0, count: count)
        var active = -1
        if tc < 2 * Double(count) * slotDur {
            let slot = Int(floor(tc / slotDur))
            let p = (tc - Double(slot) * slotDur) / slotDur
            let cl = min(1, p / 0.7)
            let ep = 1 - pow(1 - cl, 3)
            if slot < count {
                for i in 0..<slot { amount[i] = 1 }
                amount[slot] = ep
                active = slot
            } else {
                let u = 2 * count - 1 - slot
                for i in 0..<u { amount[i] = 1 }
                amount[u] = 1 - ep
                active = u
            }
        }
        return (amount, active)
    }

    private static func applyMoves(_ p: (Double, Double, Double), _ moves: [Move],
                                   _ sc: (amount: [Double], active: Int)) -> (Double, Double, Double, Bool) {
        var (x, y, z) = p
        var inActive = false
        for i in 0..<moves.count {
            if sc.amount[i] <= 0 { continue }
            let mv = moves[i]
            let coord = mv.axis == 0 ? x : mv.axis == 1 ? y : z
            if coord < mv.lo || coord >= mv.hi { continue }
            if i == sc.active { inActive = true }
            let a = mv.ang * sc.amount[i]
            let ca = cos(a), sa = sin(a)
            if mv.axis == 0 {
                let y2 = y * ca - z * sa
                z = y * sa + z * ca
                y = y2
            } else if mv.axis == 1 {
                let x2 = x * ca + z * sa
                z = -x * sa + z * ca
                x = x2
            } else {
                let x2 = x * ca - y * sa
                y = x * sa + y * ca
                x = x2
            }
        }
        return (x, y, z, inActive)
    }

    private static func makeMoves(_ count: Int) -> [Move] {
        (0..<count).map { i in
            let d = Double(i)
            let axis = min(2, Int(floor(hashD(d, 2.3) * 3)))
            let lo = -1.0 + 0.5 * min(3, floor(hashD(d, 5.9) * 4))
            let dir: Double = hashD(d, 7.7) < 0.5 ? 1 : -1
            return Move(axis: axis, lo: lo, hi: lo + 0.5, ang: (dir * .pi) / 2)
        }
    }

    static func rubik(_ size: Double, _ t: Double, _ o: OrbOpts) -> OrbFrame {
        let cx = size / 2, cy = size / 2
        let R = (size / 2) * 0.82
        let pt = makeProj(t * 0.55, 0.35 + 0.1 * sin(t * 0.9), cx, cy, R)
        let rs = radiusScale(size, o["rsPow"] ?? 0.6)
        let moveCount = Int(o["moveCount"] ?? 14)
        let moves = makeMoves(moveCount)
        let sc = solveCycle(t, moveCount, 0.42, 1.2)
        let rBase = o["rBase"] ?? 0.6, rDepth = o["rDepth"] ?? 1.7, rActive = o["rActive"] ?? 0.3
        let inkFar = o["inkFar"] ?? 0.62, inkSpan = o["inkSpan"] ?? 0.54

        var dots: [OrbDot] = []
        let latRings = Int(o["latRings"] ?? 15)
        let lonDensity = o["lonDensity"] ?? 40
        for li in 0...latRings {
            let lat = -Double.pi / 2 + (Double(li) / Double(latRings)) * .pi
            let cosLat = cos(lat), sinLat = sin(lat)
            let lonCount = max(1, Int(jsRound(abs(cosLat) * lonDensity)))
            for lj in 0..<lonCount {
                let lon = (Double(lj) / Double(lonCount)) * 2 * .pi
                let (x, y, z, inActive) = applyMoves((cosLat * cos(lon), sinLat, cosLat * sin(lon)), moves, sc)
                let (px, py, zr) = pt(x, y, z)
                let depth = (zr + 1) / 2
                dots.append(OrbDot(x: px, y: py, z: zr,
                                   r: (rBase + rDepth * depth + (inActive ? rActive : 0)) * rs,
                                   white: inkFar - inkSpan * depth - (inActive ? 0.14 : 0)))
            }
        }
        return finalizeFrame(dots, [], o["rMin"] ?? 0.3)
    }

    // MARK: - Wave — listening

    static func wave(_ size: Double, _ t: Double, _ o: OrbOpts) -> OrbFrame {
        let cx = size / 2, cy = size / 2
        let R = (size / 2) * 0.874
        let pt = makeProj(t * 0.18, 0.38, cx, cy, 1)
        let rs = radiusScale(size, o["rsPow"] ?? 0.6)
        let rBase = o["rBase"] ?? 0.6, rDepth = o["rDepth"] ?? 1.7

        var dots: [OrbDot] = []
        let rings = Int(o["rings"] ?? 15)
        let lonDensity = o["lonDensity"] ?? 40
        for ri in 0...rings {
            let r = Double(ri)
            let lat = -Double.pi / 2 + (r / Double(rings)) * .pi
            let cosLat = cos(lat), sinLat = sin(lat)
            let w = 0.62 * sin(t * 2.1 - r * 0.52) + 0.38 * sin(t * 1.27 + r * 0.83)
            let rr = R * (0.88 + 0.105 * w)
            let lonCount = max(1, Int(jsRound(abs(cosLat) * lonDensity)))
            for lj in 0..<lonCount {
                let lon = (Double(lj) / Double(lonCount)) * 2 * .pi
                let (px, py, z) = pt(cosLat * cos(lon) * rr, sinLat * rr, cosLat * sin(lon) * rr)
                let depth = (z / R + 1) / 2
                let crest = max(0, w)
                dots.append(OrbDot(x: px, y: py, z: z,
                                   r: (rBase + rDepth * depth) * (1 + 0.4 * crest) * rs,
                                   white: 0.66 - 0.56 * depth - 0.1 * crest))
            }
        }
        return finalizeFrame(dots, [], o["rMin"] ?? 0.3)
    }

    // MARK: - Web — connecting

    static func web(_ size: Double, _ t: Double, _ o: OrbOpts) -> OrbFrame {
        let cx = size / 2, cy = size / 2
        let R = (size / 2) * 0.8 * (o["spread"] ?? 1)
        let pt = makeProj(t * 0.12, 0.32, cx, cy, R)
        let rs = radiusScale(size, o["rsPow"] ?? 0.6)
        let nodeN = Int(o["nodeN"] ?? 30)
        let thr = o["thr"] ?? 0.72
        let nodeR = o["nodeR"] ?? 1.4
        let nodeRDepth = o["nodeRDepth"] ?? 1.8
        let lineW = o["lineW"] ?? 0.8

        var nodes: [(Double, Double, Double)] = []
        nodes.reserveCapacity(nodeN)
        for i in 0..<nodeN {
            let d = fibDir(i, nodeN)
            let fi = Double(i)
            let x = d.0 + 0.3 * (vnoise(fi * 0.31 + 9, t * 0.24) - 0.5) * 2
            let y = d.1 + 0.3 * (vnoise(fi * 0.53 + 27, t * 0.21) - 0.5) * 2
            let z = d.2 + 0.3 * (vnoise(fi * 0.77 + 55, t * 0.27) - 0.5) * 2
            let l = (x * x + y * y + z * z).squareRoot()
            nodes.append((x / l, y / l, z / l))
        }

        var lines: [OrbLine] = []
        var dots: [OrbDot] = []
        for i in 0..<nodeN {
            for j in (i + 1)..<max(i + 1, nodeN) {
                let dx = nodes[i].0 - nodes[j].0
                let dy = nodes[i].1 - nodes[j].1
                let dz = nodes[i].2 - nodes[j].2
                let dist = (dx * dx + dy * dy + dz * dz).squareRoot()
                if dist >= thr { continue }
                let (x1, y1, z1) = pt(nodes[i].0, nodes[i].1, nodes[i].2)
                let (x2, y2, z2) = pt(nodes[j].0, nodes[j].1, nodes[j].2)
                let depth = ((z1 + z2) / 2 + 1) / 2
                lines.append(OrbLine(x1: x1, y1: y1, x2: x2, y2: y2, white: 0.42,
                                     a: (1 - dist / thr) * (0.3 + 0.55 * depth),
                                     w: max(0.6, lineW * rs)))
            }
        }

        for i in 0..<nodeN {
            let (px, py, z) = pt(nodes[i].0, nodes[i].1, nodes[i].2)
            let depth = (z + 1) / 2
            let pulse = 1 + 0.25 * sin(t * 1.4 + Double(i) * 2.7)
            dots.append(OrbDot(x: px, y: py, z: z, r: (nodeR + nodeRDepth * depth) * pulse * rs, white: 0.55 - 0.45 * depth))
        }

        let signals = Int(o["signals"] ?? 5)
        for s in 0..<signals {
            let fs = Double(s)
            let seg = floor(t * 0.55 + fs * 7.31)
            let a = Int(floor(hashD(seg, fs * 3.1 + 1.7) * Double(nodeN)))
            let b = Int(floor(hashD(seg, fs * 5.7 + 4.2) * Double(nodeN)))
            if a == b { continue }
            let f = frac(t * 0.55 + fs * 7.31)
            let x = lerp(nodes[a].0, nodes[b].0, f)
            let y = lerp(nodes[a].1, nodes[b].1, f)
            let z = lerp(nodes[a].2, nodes[b].2, f)
            let l = max(1e-6, (x * x + y * y + z * z).squareRoot())
            let (px, py, zr) = pt(x / l, y / l, z / l)
            let depth = (zr + 1) / 2
            dots.append(OrbDot(x: px, y: py, z: zr, r: (nodeR * 1.5 + nodeRDepth * depth) * rs, white: 0.05, a: 0.5 + 0.5 * depth))
        }
        return finalizeFrame(dots, lines, o["rMin"] ?? 0.3)
    }

    // MARK: - Braid — weaving

    static func braid(_ size: Double, _ t: Double, _ o: OrbOpts) -> OrbFrame {
        let cx = size / 2, cy = size / 2
        let R = (size / 2) * 0.76
        let pt = makeProj(t * 0.4, 0.3, cx, cy, 1)
        let rs = radiusScale(size, o["rsPow"] ?? 0.6)
        let rBase = o["rBase"] ?? 1.2, rDepth = o["rDepth"] ?? 1.8

        var dots: [OrbDot] = []
        let ghostN = Int(o["ghostN"] ?? 150)
        for i in 0..<ghostN {
            let d = fibDir(i, ghostN)
            let (px, py, z) = pt(d.0 * R, d.1 * R, d.2 * R)
            let depth = (z / R + 1) / 2
            dots.append(OrbDot(x: px, y: py, z: z, r: 0.8 * rs, white: 0.78, a: 0.1 + 0.22 * depth))
        }

        let strandN = Int(o["strandN"] ?? 52)
        let turns = o["turns"] ?? 3
        for s in 0..<3 {
            let phase = (Double(s) / 3) * 2 * .pi
            for i in 0..<strandN {
                let u = (frac(Double(i) / Double(strandN) + t * 0.045) * 2 - 1) * 0.96
                let surf = max(0, 1 - u * u).squareRoot()
                let endFade = min(1, (1 - abs(u)) / 0.1)
                let a = u * .pi * turns + phase
                let weave = 1 + 0.075 * sin(u * .pi * turns * 2 + phase * 2 + t * 0.8)
                let rr = surf * R * weave
                let (px, py, zr) = pt(cos(a) * rr, u * R * weave, sin(a) * rr)
                let depth = (zr / R + 1) / 2
                dots.append(OrbDot(x: px, y: py, z: zr, r: (rBase + rDepth * depth) * rs,
                                   white: 0.55 - 0.45 * depth, a: endFade * (0.45 + 0.55 * depth)))
            }
        }
        return finalizeFrame(dots, [], o["rMin"] ?? 0.3)
    }

    // MARK: - Ribbon — composing (and ring — breathing, via faceOn)

    static func ribbon(_ size: Double, _ t: Double, _ o: OrbOpts) -> OrbFrame {
        let cx = size / 2, cy = size / 2
        let R = (size / 2) * 0.78
        let spin = o["spin"] ?? 1
        let camTilt = 0.3
        let pt = makeProj(t * 0.1 * spin, camTilt, cx, cy, 1)
        let rs = radiusScale(size, o["rsPow"] ?? 0.6)
        let faceOn = (o["faceOn"] ?? 0) != 0
        let rBase = o["rBase"] ?? 1.1, rDepth = o["rDepth"] ?? 1.7
        let wobMul = o["wobMul"] ?? 1

        var dots: [OrbDot] = []
        let ghostN = Int(o["ghostN"] ?? 150)
        for i in 0..<ghostN {
            let d = fibDir(i, ghostN)
            let (px, py, z) = pt(d.0 * R, d.1 * R, d.2 * R)
            let depth = (z / R + 1) / 2
            dots.append(OrbDot(x: px, y: py, z: z, r: 0.8 * rs, white: 0.78, a: 0.1 + 0.22 * depth))
        }

        let ya = t * 0.24 * spin
        let ta = faceOn ? -camTilt : 0.55 + 0.3 * sin(t * 0.18) * spin
        let ux = cos(ya), uy = 0.0, uz = sin(ya)
        let vx = -uz * sin(ta)
        let vy = cos(ta)
        let vz = ux * sin(ta)
        let nx = uy * vz - uz * vy
        let ny = uz * vx - ux * vz
        let nz = ux * vy - uy * vx

        let wobAmp = 0.23 * wobMul
        let baseR = faceOn ? R / (1 + 0.85 * wobAmp) : R

        let baseLanes = o["lanes"] ?? 5
        let segs = Int(o["segs"] ?? 88)
        let lanes = max(1, Int(jsRound(baseLanes * (o["bandMul"] ?? 1))))
        let mid = Double(lanes - 1) / 2
        for w in 0..<lanes {
            let fw = Double(w)
            let laneOff = (fw - mid) * 0.075
            let edge = abs(fw - mid) / max(1, mid)
            for k in 0..<segs {
                let a = (Double(k) / Double(segs)) * 2 * .pi
                let wob = (0.16 * sin(a * 3 - t * 1.7 + fw * 0.22) + 0.07 * sin(a * 5 + t * 1.1)) * wobMul
                let radial = faceOn ? 1 + wob : 1
                let off = faceOn ? laneOff : laneOff + wob
                let x = ux * cos(a) + vx * sin(a) + nx * off
                let y = uy * cos(a) + vy * sin(a) + ny * off
                let z = uz * cos(a) + vz * sin(a) + nz * off
                let l = (x * x + y * y + z * z).squareRoot()
                let rr = baseR * radial
                let (px, py, zr) = pt((x / l) * rr, (y / l) * rr, (z / l) * rr)
                let depth = (zr / R + 1) / 2
                dots.append(OrbDot(x: px, y: py, z: zr,
                                   r: (rBase + rDepth * depth) * (1 - 0.25 * edge) * rs,
                                   white: 0.52 - 0.44 * depth + 0.18 * edge,
                                   a: 0.4 + 0.6 * depth))
            }
        }
        return finalizeFrame(dots, [], o["rMin"] ?? 0.3)
    }

    // MARK: - Morph — shaping

    private typealias ShapePath = (Double) -> (Double, Double)

    private static func polyPath(_ verts: [(Double, Double)]) -> ShapePath {
        let V = verts.count
        var L: [Double] = []
        var total = 0.0
        for i in 0..<V {
            let a = verts[i], b = verts[(i + 1) % V]
            let l = jsHypot(b.0 - a.0, b.1 - a.1)
            L.append(l)
            total += l
        }
        return { f in
            var target = f * total
            var i = 0
            while target > L[i] && i < V - 1 {
                target -= L[i]
                i += 1
            }
            let a = verts[i], b = verts[(i + 1) % V]
            let ff = L[i] != 0 ? min(1, target / L[i]) : 0
            return (a.0 + (b.0 - a.0) * ff, a.1 + (b.1 - a.1) * ff)
        }
    }

    private static let shapeCycle: [ShapePath] = [
        { f in
            let a = -Double.pi / 2 + f * 2 * .pi
            return (cos(a) * 0.24, sin(a) * 0.24)
        },
        polyPath([(0.0, -0.26), (0.24, 0.16), (-0.24, 0.16)]),
        // 5-vertex walk so the path STARTS at top-centre like the other shapes
        polyPath([(0, -0.2), (0.2, -0.2), (0.2, 0.2), (-0.2, 0.2), (-0.2, -0.2)]),
    ]

    static func morph(_ size: Double, _ t: Double, _ o: OrbOpts) -> OrbFrame {
        let hold = 1.4, morphDur = 0.9
        let seg = hold + morphDur
        let K = shapeCycle.count
        let tc = jsMod(t, seg * Double(K))
        // `t` is a huge absolute wall-clock value, so `tc` can round to
        // exactly `seg * K` at the wrap boundary (floating-point rounding
        // in `truncatingRemainder`), which floors to `k == K` — one past
        // the end of `shapeCycle`. Clamp defensively instead of trapping.
        let k = min(K - 1, max(0, Int(floor(tc / seg))))
        let local = tc - Double(k) * seg
        let m: Double = {
            guard local > hold else { return 0 }
            let x = (local - hold) / morphDur
            return x * x * (3 - 2 * x)
        }()
        let sprd = o["spread"] ?? 1

        let pA = shapeCycle[k], pB = shapeCycle[(k + 1) % K]
        let M = 160
        var pts: [(Double, Double)] = []
        pts.reserveCapacity(M)
        for i in 0..<M {
            let f = Double(i) / Double(M)
            let a = pA(f), b = pB(f)
            pts.append(((a.0 + (b.0 - a.0) * m) * sprd, (a.1 + (b.1 - a.1) * m) * sprd))
        }
        var L: [Double] = []
        L.reserveCapacity(M)
        var total = 0.0
        for i in 0..<M {
            let a = pts[i], b = pts[(i + 1) % M]
            let l = jsHypot(b.0 - a.0, b.1 - a.1)
            L.append(l)
            total += l
        }

        let n = max(6, Int(jsRound(34 * (o["iconD"] ?? 1))))
        let re = (o["rDot"] ?? 0.021) * 1.35 * sprd
        let pulse = 1 + 0.02 * sin(local * 3.1)

        var dots: [OrbDot] = []
        let c2 = size / 2
        var s = 0
        var acc = 0.0
        for k2 in 0..<n {
            let target = (Double(k2) / Double(n)) * total
            while acc + L[s] < target && s < M - 1 {
                acc += L[s]
                s += 1
            }
            let a = pts[s], b = pts[(s + 1) % M]
            let f = L[s] != 0 ? min(1, (target - acc) / L[s]) : 0
            let x = (a.0 + (b.0 - a.0) * f) * pulse
            let y = (a.1 + (b.1 - a.1) * f) * pulse
            dots.append(OrbDot(x: c2 + x * size, y: c2 + y * size, z: 0, r: max(0.35, re * size), white: 0.1))
        }
        return finalizeFrame(dots, [], o["rMin"] ?? 0.3)
    }
}
