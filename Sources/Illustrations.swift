import SwiftUI

enum Palette {
    static let bgTop = Color(red: 0.07, green: 0.075, blue: 0.12)
    static let bgBottom = Color(red: 0.13, green: 0.11, blue: 0.17)
    static let ink = Color(red: 0.93, green: 0.90, blue: 0.85)
    static let cool = Color(red: 0.56, green: 0.74, blue: 0.90)   // inhale: thandak
    static let warm = Color(red: 0.93, green: 0.64, blue: 0.46)   // exhale: garmi
    static let gold = Color(red: 0.92, green: 0.78, blue: 0.47)
}

/// The animated drawing for whatever step is running.
struct PhaseArt: View {
    @ObservedObject var session: Session

    var body: some View {
        TimelineView(.animation(paused: session.paused)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let design = CGSize(width: 300, height: 320)
                let s = min(size.width / design.width, size.height / design.height)
                ctx.translateBy(x: (size.width - design.width * s) / 2, y: (size.height - design.height * s) / 2)
                ctx.scaleBy(x: s, y: s)
                switch session.phase.kind {
                case .settle: Art.settle(&ctx, t: t, elapsed: session.elapsed, badDay: session.badDay)
                case .nadi: Art.nadi(&ctx, t: t, step: session.pacerStep, progress: session.pacerProgress,
                                     closedLabels: true)
                case .bhramari: Art.bhramari(&ctx, t: t)
                case .witness: Art.witness(&ctx, t: t)
                case .visualize: Art.visualize(&ctx, t: t, elapsed: session.elapsed)
                case .sankalpa, .guided: Art.sankalpa(&ctx, t: t)
                case .close: Art.close(&ctx, t: t, elapsed: session.elapsed)
                }
            }
        }
    }
}

enum Art {
    static let line = StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round)

    static func label(_ ctx: inout GraphicsContext, _ s: String, at p: CGPoint, opacity: Double = 0.5, size: CGFloat = 10) {
        ctx.draw(Text(s).font(.system(size: size, weight: .regular, design: .rounded))
            .foregroundColor(Palette.ink.opacity(opacity)), at: p)
    }

    static func glow(_ ctx: inout GraphicsContext, at p: CGPoint, r: CGFloat, color: Color, strength: Double = 1) {
        let rect = CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r)
        ctx.fill(Path(ellipseIn: rect), with: .radialGradient(
            Gradient(colors: [color.opacity(0.55 * strength), color.opacity(0)]),
            center: p, startRadius: 0, endRadius: r))
    }

    // MARK: Seated figure (300 x 320 space)

    static func figure(_ ctx: inout GraphicsContext, breath: Double = 0) {
        var p = Path()
        p.addEllipse(in: CGRect(x: 126, y: 40, width: 48, height: 52))       // head
        p.move(to: CGPoint(x: 144, y: 92)); p.addLine(to: CGPoint(x: 144, y: 104))
        p.move(to: CGPoint(x: 156, y: 92)); p.addLine(to: CGPoint(x: 156, y: 104))
        let bw = 1 + 0.04 * breath
        // torso
        p.move(to: CGPoint(x: 144, y: 104))
        p.addQuadCurve(to: CGPoint(x: 108, y: 122), control: CGPoint(x: 116, y: 106))
        p.addQuadCurve(to: CGPoint(x: 150 - 34 * bw, y: 212), control: CGPoint(x: 150 - 44 * bw, y: 170))
        p.move(to: CGPoint(x: 156, y: 104))
        p.addQuadCurve(to: CGPoint(x: 192, y: 122), control: CGPoint(x: 184, y: 106))
        p.addQuadCurve(to: CGPoint(x: 150 + 34 * bw, y: 212), control: CGPoint(x: 150 + 44 * bw, y: 170))
        // arms
        p.move(to: CGPoint(x: 110, y: 126))
        p.addQuadCurve(to: CGPoint(x: 82, y: 222), control: CGPoint(x: 86, y: 170))
        p.move(to: CGPoint(x: 190, y: 126))
        p.addQuadCurve(to: CGPoint(x: 218, y: 222), control: CGPoint(x: 214, y: 170))
        // crossed legs
        p.move(to: CGPoint(x: 116, y: 212))
        p.addQuadCurve(to: CGPoint(x: 50, y: 240), control: CGPoint(x: 64, y: 214))
        p.addQuadCurve(to: CGPoint(x: 150, y: 262), control: CGPoint(x: 70, y: 262))
        p.addQuadCurve(to: CGPoint(x: 250, y: 240), control: CGPoint(x: 230, y: 262))
        p.addQuadCurve(to: CGPoint(x: 184, y: 212), control: CGPoint(x: 236, y: 214))
        p.move(to: CGPoint(x: 92, y: 246)); p.addQuadCurve(to: CGPoint(x: 196, y: 236), control: CGPoint(x: 150, y: 226))
        // cushion
        p.move(to: CGPoint(x: 40, y: 272)); p.addQuadCurve(to: CGPoint(x: 260, y: 272), control: CGPoint(x: 150, y: 286))
        ctx.stroke(p, with: .color(Palette.ink.opacity(0.55)), style: line)
    }

    static func noseBreath(_ ctx: inout GraphicsContext, t: Double, period: Double = 12) {
        let ph = (t.truncatingRemainder(dividingBy: period)) / period
        let inhale = ph < 0.5
        let k = inhale ? ph * 2 : (ph - 0.5) * 2
        for i in 0..<7 {
            let f = (k * 0.5 + Double(i) / 7).truncatingRemainder(dividingBy: 1)
            let d = inhale ? 1 - f : f
            let p = CGPoint(x: 150 + 2 * sin(Double(i)), y: 76 + d * 34)
            let a = sin(.pi * f) * 0.8
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - 1.6, y: p.y - 1.6, width: 3.2, height: 3.2)),
                     with: .color((inhale ? Palette.cool : Palette.warm).opacity(a)))
        }
    }

    // MARK: Step 1

    static func settle(_ ctx: inout GraphicsContext, t: Double, elapsed: Double, badDay: Bool) {
        let breath = sin(t * 2 * .pi / 10)
        glow(&ctx, at: CGPoint(x: 150, y: 170), r: 120, color: Palette.gold, strength: 0.25 + 0.1 * breath)
        figure(&ctx, breath: breath)
        let spots: [(ClosedRange<Double>, [CGPoint], String)] = [
            (35...45, [CGPoint(x: 150, y: 56)], "maatha"),
            (45...55, [CGPoint(x: 150, y: 84)], "jabda"),
            (55...65, [CGPoint(x: 116, y: 118), CGPoint(x: 184, y: 118)], "kandhe"),
            (65...75, [CGPoint(x: 150, y: 180)], "pet"),
            (75...84, [CGPoint(x: 82, y: 222), CGPoint(x: 218, y: 222)], "haath"),
        ]
        if !badDay {
            for (range, pts, name) in spots where range.contains(elapsed) {
                let k = min(1, (elapsed - range.lowerBound) / 1.5) * min(1, (range.upperBound - elapsed) / 1.5)
                for p in pts { glow(&ctx, at: p, r: 26 + 4 * sin(t * 0.6), color: Palette.gold, strength: 1.4 * k) }
            }
        }
        if elapsed > 84 || badDay {
            noseBreath(&ctx, t: t)
            label(&ctx, "andar thandak · bahar garmi", at: CGPoint(x: 150, y: 300), opacity: 0.45)
        }
    }

    // MARK: Step 2 — airway diagram

    static let nostrilL = CGPoint(x: 140, y: 96), nostrilR = CGPoint(x: 160, y: 96)

    static func airway(_ side: Nostril, lung: Nostril) -> [CGPoint] {
        let sx: CGFloat = side == .left ? -1 : 1
        let lx: CGFloat = lung == .left ? -1 : 1
        return [
            CGPoint(x: 150 + sx * 12, y: 118), CGPoint(x: 150 + sx * 10, y: 98),
            CGPoint(x: 150 + sx * 11, y: 84), CGPoint(x: 150 + sx * 5, y: 108),
            CGPoint(x: 150, y: 128), CGPoint(x: 150, y: 176),
            CGPoint(x: 150 + lx * 16, y: 192), CGPoint(x: 150 + lx * 38, y: 214),
            CGPoint(x: 150 + lx * 42, y: 240),
        ]
    }

    static func point(on pts: [CGPoint], at s: Double) -> CGPoint {
        var lens: [Double] = []
        for i in 1..<pts.count { lens.append(hypot(pts[i].x - pts[i - 1].x, pts[i].y - pts[i - 1].y)) }
        var d = s * lens.reduce(0, +)
        for i in 0..<lens.count {
            if d <= lens[i] {
                let k = d / lens[i]
                return CGPoint(x: pts[i].x + (pts[i + 1].x - pts[i].x) * k, y: pts[i].y + (pts[i + 1].y - pts[i].y) * k)
            }
            d -= lens[i]
        }
        return pts.last!
    }

    static func nadi(_ ctx: inout GraphicsContext, t: Double, step: PacerStep?, progress: Double, closedLabels: Bool) {
        // breath amount: 0 empty ... 1 full
        var fill = 0.5 + 0.5 * sin(t * 2 * .pi / 12)
        if let s = step { fill = s.inhale ? progress : 1 - progress }
        let e = fill * fill * (3 - 2 * fill)

        // face
        ctx.stroke(Path(ellipseIn: CGRect(x: 96, y: 8, width: 108, height: 132)),
                   with: .color(Palette.ink.opacity(0.25)), style: line)
        var nose = Path()
        nose.move(to: CGPoint(x: 150, y: 54)); nose.addQuadCurve(to: CGPoint(x: 130, y: 96), control: CGPoint(x: 146, y: 80))
        nose.addQuadCurve(to: CGPoint(x: 150, y: 104), control: CGPoint(x: 134, y: 106))
        nose.addQuadCurve(to: CGPoint(x: 170, y: 96), control: CGPoint(x: 166, y: 106))
        ctx.stroke(nose, with: .color(Palette.ink.opacity(0.3)), style: line)
        for n in [nostrilL, nostrilR] {
            ctx.fill(Path(ellipseIn: CGRect(x: n.x - 4, y: n.y - 2, width: 8, height: 4.5)), with: .color(Palette.ink.opacity(0.45)))
        }

        // airways
        var tube = Path()
        for side in [Nostril.left, .right] {
            let a = airway(side, lung: side)
            tube.move(to: a[1]); for p in a[2...5] { tube.addLine(to: p) }
        }
        for lung in [Nostril.left, .right] {
            let a = airway(.left, lung: lung)
            tube.move(to: a[5]); for p in a[6...8] { tube.addLine(to: p) }
        }
        ctx.stroke(tube, with: .color(Palette.ink.opacity(0.16)), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))

        // lungs
        for lx in [-1.0, 1.0] {
            let w = 58 + 10 * e, h = 88 + 12 * e
            let c = CGPoint(x: 150 + lx * 44, y: 234 + 4 * e)
            let r = CGRect(x: c.x - w / 2, y: c.y - h / 2, width: w, height: h)
            let lungPath = Path(roundedRect: r, cornerRadius: w * 0.48)
            ctx.fill(lungPath, with: .color(Palette.cool.opacity(0.06 + 0.12 * e)))
            ctx.stroke(lungPath, with: .color(Palette.ink.opacity(0.4)), style: line)
        }
        // diaphragm: dome up when empty, flatter and lower when full
        var dia = Path()
        dia.move(to: CGPoint(x: 78, y: 292))
        dia.addQuadCurve(to: CGPoint(x: 222, y: 292), control: CGPoint(x: 150, y: 262 + 30 * e))
        ctx.stroke(dia, with: .color(Palette.gold.opacity(0.7)), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
        let arrowY = 300 + 6 * e
        label(&ctx, fill > 0.5 ? "↓ diaphragm · pet bahar" : "diaphragm", at: CGPoint(x: 150, y: arrowY + 10), opacity: 0.45, size: 9)

        label(&ctx, "baayaan", at: CGPoint(x: 112, y: 124), opacity: 0.5, size: 9)
        label(&ctx, "daayaan", at: CGPoint(x: 188, y: 124), opacity: 0.5, size: 9)
        label(&ctx, "phephde", at: CGPoint(x: 150, y: 214), opacity: 0.35, size: 9)

        guard let s = step else { return }
        // finger closing the other nostril
        let closed = s.side == .left ? nostrilR : nostrilL
        let fingerPt = CGPoint(x: closed.x + (s.side == .left ? 4 : -4), y: closed.y - 4)
        ctx.fill(Path(roundedRect: CGRect(x: fingerPt.x - 9, y: fingerPt.y - 14, width: 18, height: 28), cornerRadius: 9),
                 with: .color(Palette.ink.opacity(0.18)))
        ctx.stroke(Path(roundedRect: CGRect(x: fingerPt.x - 9, y: fingerPt.y - 14, width: 18, height: 28), cornerRadius: 9),
                   with: .color(Palette.ink.opacity(0.5)), lineWidth: 1)
        if closedLabels {
            label(&ctx, s.side == .left ? "angootha" : "anamika", at: CGPoint(x: fingerPt.x + (s.side == .left ? 36 : -36), y: fingerPt.y - 6), opacity: 0.5, size: 9)
        }
        glow(&ctx, at: s.side == .left ? nostrilL : nostrilR, r: 18, color: s.inhale ? Palette.cool : Palette.warm, strength: 1.2)

        // flowing air
        let color = s.inhale ? Palette.cool : Palette.warm
        // a short train of air that travels exactly as far as the breath has gone
        let head = s.inhale ? progress : 1 - progress
        for i in 0..<10 {
            for lung in [Nostril.left, .right] {
                let path = airway(s.side, lung: lung)
                let sPos = s.inhale ? head - Double(i) * 0.035 : head + Double(i) * 0.035
                guard sPos >= 0, sPos <= 1 else { continue }
                let p = point(on: path, at: sPos)
                let a = 0.9 * (1 - Double(i) / 10)
                ctx.fill(Path(ellipseIn: CGRect(x: p.x - 2.4, y: p.y - 2.4, width: 4.8, height: 4.8)), with: .color(color.opacity(a)))
            }
        }
    }

    // MARK: Step 3 — humming head

    static func bhramari(_ ctx: inout GraphicsContext, t: Double) {
        let head = CGRect(x: 90, y: 40, width: 120, height: 150)
        glow(&ctx, at: CGPoint(x: 150, y: 120), r: 110, color: Palette.gold, strength: 0.25)
        // vibration rings from the throat, wobbling
        for i in 0..<5 {
            let k = (t * 0.1 + Double(i) / 5).truncatingRemainder(dividingBy: 1)
            let r = 12 + 90 * k
            var ring = Path()
            let c = CGPoint(x: 150, y: 150)
            for a in stride(from: 0.0, through: 2 * .pi + 0.01, by: .pi / 60) {
                let rr = r + 1.2 * min(1, r / 60) * sin(a * 10 + t * 1.5)
                let p = CGPoint(x: c.x + rr * cos(a), y: c.y + rr * sin(a) * 1.15)
                if a == 0 { ring.move(to: p) } else { ring.addLine(to: p) }
            }
            var clipped = ctx
            clipped.clip(to: Path(ellipseIn: head.insetBy(dx: 2, dy: 2)))
            clipped.stroke(ring, with: .color(Palette.gold.opacity(0.55 * (1 - k))), lineWidth: 1.2)
        }
        ctx.stroke(Path(ellipseIn: head), with: .color(Palette.ink.opacity(0.55)), style: line)
        // closed eyes & lips
        var f = Path()
        for x in [128.0, 172.0] {
            f.move(to: CGPoint(x: x - 10, y: 108)); f.addQuadCurve(to: CGPoint(x: x + 10, y: 108), control: CGPoint(x: x, y: 114))
        }
        f.move(to: CGPoint(x: 138, y: 160)); f.addLine(to: CGPoint(x: 162, y: 160))
        ctx.stroke(f, with: .color(Palette.ink.opacity(0.45)), style: line)
        // neck + larynx
        var neck = Path()
        neck.move(to: CGPoint(x: 134, y: 186)); neck.addLine(to: CGPoint(x: 134, y: 222))
        neck.move(to: CGPoint(x: 166, y: 186)); neck.addLine(to: CGPoint(x: 166, y: 222))
        ctx.stroke(neck, with: .color(Palette.ink.opacity(0.45)), style: line)
        glow(&ctx, at: CGPoint(x: 150, y: 206), r: 14 + 3 * sin(t * 2), color: Palette.gold, strength: 1.3)
        // thumbs on ears, fingers on forehead
        for sx in [-1.0, 1.0] {
            let ear = CGPoint(x: 150 + sx * 62, y: 118)
            ctx.fill(Path(roundedRect: CGRect(x: ear.x - 7, y: ear.y - 13, width: 14, height: 26), cornerRadius: 7),
                     with: .color(Palette.ink.opacity(0.2)))
            ctx.stroke(Path(roundedRect: CGRect(x: ear.x - 7, y: ear.y - 13, width: 14, height: 26), cornerRadius: 7),
                       with: .color(Palette.ink.opacity(0.5)), lineWidth: 1)
            var fing = Path()
            for j in 0..<3 {
                let y = 62 + Double(j) * 9
                fing.move(to: CGPoint(x: 150 + sx * 60, y: y + 10)); fing.addLine(to: CGPoint(x: 150 + sx * 18, y: y))
            }
            ctx.stroke(fing, with: .color(Palette.ink.opacity(0.22)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
        label(&ctx, "angootha kaan pe", at: CGPoint(x: 150, y: 244), opacity: 0.4, size: 9)
        label(&ctx, "gala → maatha, gaal, khopdi", at: CGPoint(x: 150, y: 262), opacity: 0.45, size: 10)
        label(&ctx, "hont band · mmmm", at: CGPoint(x: 150, y: 280), opacity: 0.35, size: 9)
    }

    // MARK: Step 4 — thoughts drifting past the witness

    static let thoughts = ["plan", "darr", "mic", "yaad", "guilt", "office", "gussa", "wo", "kal", "message"]

    static func witness(_ ctx: inout GraphicsContext, t: Double) {
        figure(&ctx, breath: sin(t * 2 * .pi / 9))
        // steady witness light
        glow(&ctx, at: CGPoint(x: 150, y: 150), r: 34, color: Palette.gold, strength: 1.0)
        ctx.fill(Path(ellipseIn: CGRect(x: 147, y: 147, width: 6, height: 6)), with: .color(Palette.gold.opacity(0.9)))
        noseBreath(&ctx, t: t, period: 9)
        // thoughts float up and dissolve
        let life = 16.0, every = 6.0
        let newest = Int(t / every)
        for k in (newest - 3)...newest {
            let age = t - Double(k) * every
            guard age >= 0, age < life else { continue }
            let f = age / life
            let side = k % 2 == 0 ? -1.0 : 1.0
            let x = 150 + side * (40 + 30 * f) + 6 * sin(age * 0.3)
            let y = 60 - 20 * f + (k % 3 == 0 ? 20 : 0)
            let a = sin(.pi * f) * 0.7
            let word = thoughts[((k % thoughts.count) + thoughts.count) % thoughts.count]
            let w = CGFloat(word.count) * 7 + 18
            let bubble = Path(roundedRect: CGRect(x: x - w / 2, y: y - 11, width: w, height: 22), cornerRadius: 11)
            ctx.stroke(bubble, with: .color(Palette.ink.opacity(a * 0.5)), lineWidth: 1)
            label(&ctx, word, at: CGPoint(x: x, y: y), opacity: a, size: 11)
        }
        label(&ctx, "thoughts aate-jaate · dekhne wala wahin", at: CGPoint(x: 150, y: 300), opacity: 0.4, size: 10)
    }

    // MARK: Visualization

    static func visualize(_ ctx: inout GraphicsContext, t: Double, elapsed: Double) {
        let breath = 0.5 + 0.5 * sin(t * 2 * .pi / 9)
        let heart = CGPoint(x: 150, y: 150)
        if elapsed < 70 || elapsed >= 165 {
            // light at the heart, spreading through the body
            let spread = elapsed >= 165 ? 0.25 : min(1, max(0, (elapsed - 25) / 40))
            glow(&ctx, at: heart, r: 30 + 150 * spread + 12 * breath, color: Palette.gold, strength: 0.6 + 0.3 * spread)
            glow(&ctx, at: heart, r: 22 + 6 * breath, color: Palette.gold, strength: 1.4)
            figure(&ctx, breath: breath)
            if spread > 0.3 && elapsed < 70 {
                for p in [CGPoint(x: 82, y: 222), CGPoint(x: 218, y: 222), CGPoint(x: 116, y: 118), CGPoint(x: 184, y: 118)] {
                    glow(&ctx, at: p, r: 20, color: Palette.gold, strength: (spread - 0.3) * 1.2)
                }
            }
            return
        }
        // the day as an arc: subah -> mushkil pal -> raat/mic
        let k = min(1, (elapsed - 70) / 90)
        var arc = Path()
        arc.move(to: CGPoint(x: 40, y: 230))
        arc.addQuadCurve(to: CGPoint(x: 260, y: 230), control: CGPoint(x: 150, y: 40))
        ctx.stroke(arc, with: .color(Palette.ink.opacity(0.25)), style: StrokeStyle(lineWidth: 1.4, dash: [3, 6]))
        func at(_ u: Double) -> CGPoint {
            let x = (1 - u) * (1 - u) * 40 + 2 * (1 - u) * u * 150 + u * u * 260
            let y = (1 - u) * (1 - u) * 230 + 2 * (1 - u) * u * 40 + u * u * 230
            return CGPoint(x: x, y: y)
        }
        let marks: [(Double, String)] = [(0.05, "subah"), (0.5, "mushkil pal"), (0.95, "raat · mic")]
        for (u, name) in marks {
            let p = at(u)
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - 3, y: p.y - 3, width: 6, height: 6)), with: .color(Palette.ink.opacity(0.4)))
            label(&ctx, name, at: CGPoint(x: p.x, y: p.y + (u == 0.5 ? -16 : 18)), opacity: 0.5, size: 10)
        }
        let me = at(k)
        glow(&ctx, at: me, r: 34 + 6 * breath, color: Palette.gold, strength: 1.1)
        ctx.fill(Path(ellipseIn: CGRect(x: me.x - 4, y: me.y - 4, width: 8, height: 8)), with: .color(Palette.gold))
        // ground line for the mic moment
        if elapsed >= 135 {
            var g = Path(); g.move(to: CGPoint(x: 200, y: 262)); g.addLine(to: CGPoint(x: 280, y: 262))
            ctx.stroke(g, with: .color(Palette.ink.opacity(0.35)), lineWidth: 1.2)
        }
        label(&ctx, "roshni tumhare saath", at: CGPoint(x: 150, y: 300), opacity: 0.4, size: 10)
    }

    // MARK: Step 5

    static func sankalpa(_ ctx: inout GraphicsContext, t: Double) {
        let pulse = 0.5 + 0.5 * sin(t * 2 * .pi / 10)
        glow(&ctx, at: CGPoint(x: 150, y: 150), r: 60 + 30 * pulse, color: Palette.gold, strength: 0.9)
        figure(&ctx, breath: pulse)
    }

    // MARK: Closing — palms

    static func palm(_ ctx: inout GraphicsContext, center c: CGPoint, mirrored: Bool, warmth: Double) {
        let r = CGRect(x: c.x - 22, y: c.y - 44, width: 44, height: 88)
        let p = Path(roundedRect: r, cornerRadius: 22)
        ctx.fill(p, with: .color(Palette.warm.opacity(0.08 + 0.3 * warmth)))
        ctx.stroke(p, with: .color(Palette.ink.opacity(0.5)), style: line)
        var fl = Path()
        for i in 1...3 {
            let x = r.minX + CGFloat(i) * 11
            fl.move(to: CGPoint(x: x, y: r.minY + 6)); fl.addLine(to: CGPoint(x: x, y: r.minY + 34))
        }
        ctx.stroke(fl, with: .color(Palette.ink.opacity(0.2)), lineWidth: 1)
    }

    static func close(_ ctx: inout GraphicsContext, t: Double, elapsed: Double) {
        if elapsed < 10 {
            let warmth = min(1, elapsed / 8)
            let dy = 7 * sin(t * 5)
            glow(&ctx, at: CGPoint(x: 150, y: 160), r: 60 + 50 * warmth, color: Palette.warm, strength: warmth)
            palm(&ctx, center: CGPoint(x: 126, y: 160 + dy), mirrored: false, warmth: warmth)
            palm(&ctx, center: CGPoint(x: 174, y: 160 - dy), mirrored: true, warmth: warmth)
            label(&ctx, "ragdo · garmi banne do", at: CGPoint(x: 150, y: 270), opacity: 0.45)
        } else {
            let open = elapsed >= 22
            let head = CGRect(x: 90, y: 50, width: 120, height: 150)
            glow(&ctx, at: CGPoint(x: 150, y: 120), r: 120, color: open ? Palette.gold : Palette.warm, strength: open ? 0.35 : 0.5)
            ctx.stroke(Path(ellipseIn: head), with: .color(Palette.ink.opacity(0.5)), style: line)
            if open {
                var eyes = Path()
                for x in [128.0, 172.0] {
                    eyes.addEllipse(in: CGRect(x: x - 8, y: 112, width: 16, height: 9))
                }
                ctx.stroke(eyes, with: .color(Palette.ink.opacity(0.55)), lineWidth: 1.3)
                label(&ctx, "dheere se aankhein kholo", at: CGPoint(x: 150, y: 240), opacity: 0.5)
            } else {
                for x in [128.0, 172.0] {
                    var c = ctx
                    c.rotate(by: .degrees(0))
                    palm(&c, center: CGPoint(x: x, y: 118), mirrored: x > 150, warmth: 0.8)
                }
                label(&ctx, "garam hathelian aankhon pe · 3 saans", at: CGPoint(x: 150, y: 240), opacity: 0.45)
            }
        }
    }
}
