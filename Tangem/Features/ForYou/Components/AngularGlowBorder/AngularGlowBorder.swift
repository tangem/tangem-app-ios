//
//  AngularGlowBorder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//
//  Animated angular-gradient glow border — SwiftUI port of the web rig (v17).
//  Three stacked, blurred copies of one conic gradient. The color seam rotates 360° per
//  loop via the gradient angle, while the horizontal radius "breathes" (rxMorph: wide at
//  0°/180°, narrow at 90°/270°). Seam rotation and the vertical squish are decoupled — the
//  squish stays axis-aligned and never rotates with the seam, which is what makes the morph
//  visible. When a second palette is provided, the colors also ping-pong between the two
//  sets. Each layer is a centered stroke, blurred, then clipped to the rounded box.
//

import SwiftUI
import TangemUI

struct AngularGlowBorder: View {
    var config = Config()

    /// Margin so the centered stroke's clipped outer half (and the blur falloff feeding
    /// inward) is fully rendered before the rounded-box clip cuts the outer half.
    private let margin: CGFloat = 64

    var body: some View {
        GeometryReader { proxy in
            canvas(width: proxy.size.width, height: proxy.size.height)
        }
    }

    private func canvas(width w: CGFloat, height h: CGFloat) -> some View {
        let m = margin

        return TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let f = t.truncatingRemainder(dividingBy: config.duration) / config.duration
            let phase = config.startAngle + (config.clockwise ? 1 : -1) * config.easing.value(f) * 360
            let mix = morphMix(at: t)

            Canvas { context, size in
                let box = CGRect(x: m, y: m, width: size.width - 2 * m, height: size.height - 2 * m)
                let gradient = morphedGradient(stopsA: config.stopsA, stopsB: config.stopsB, mix: mix)

                // radius morph (v17): horizontal radius breathes with the phase, ry stays fixed.
                // wide at 0°/180° (rxMax = W/2), narrow at 90°/270° (rxMin = W/8).
                let hh = box.height / 2
                let maxRx = box.width / 2
                let minRx = box.width / 8
                let mid = (maxRx + minRx) / 2
                let amp = max(0, (maxRx - minRx) / 2)
                let rx = mid + amp * CGFloat(cos(2 * phase * .pi / 180))

                // draw bottom → top so layers[0] ends on top
                for layer in config.layers.reversed() {
                    context.drawLayer { layerContext in
                        layerContext.opacity = layer.opacity
                        layerContext.addFilter(.blur(radius: layer.blur))

                        // centered stroke ring (even-odd): outer = box + s/2, inner = box - s/2
                        let o = layer.stroke / 2
                        let r = config.cornerRadius
                        var ring = Path()
                        ring.addRoundedRect(
                            in: box.insetBy(dx: -o, dy: -o),
                            cornerSize: CGSize(width: r + o, height: r + o),
                            style: .continuous
                        )
                        ring.addRoundedRect(
                            in: box.insetBy(dx: o, dy: o),
                            cornerSize: CGSize(width: max(0, r - o), height: max(0, r - o)),
                            style: .continuous
                        )
                        layerContext.clip(to: ring, style: FillStyle(eoFill: true))

                        // axis-aligned vertical squish (radius morph); the seam rotates via the
                        // gradient angle, decoupled from the squish so the morph stays visible
                        layerContext.translateBy(x: box.midX, y: box.midY)
                        layerContext.scaleBy(x: 1, y: rx > 0 ? hh / rx : 1)

                        let shading = GraphicsContext.Shading.conicGradient(
                            gradient, center: .zero, angle: .degrees(config.seamOffset + phase)
                        )
                        layerContext.fill(
                            Path(CGRect(x: -4000, y: -4000, width: 8000, height: 8000)),
                            with: shading
                        )
                    }
                }
            }
            .frame(width: w + 2 * m, height: h + 2 * m) // oversized canvas (holds outer half + blur)
            .frame(width: w, height: h) // layout footprint = the box; canvas overflows centered
            .clipShape(RoundedRectangle(cornerRadius: config.cornerRadius, style: .continuous)) // clip AFTER blur
        }
    }

    // MARK: - Gradient palette morph (v17)

    /// Ping-pong 0→1→0 over `morphDuration`; returns 0 (no morph) when there is no B palette.
    private func morphMix(at time: TimeInterval) -> CGFloat {
        guard config.stopsB != nil, config.morphDuration > 0 else { return 0 }
        let progress = time.truncatingRemainder(dividingBy: config.morphDuration) / config.morphDuration
        return CGFloat(progress < 0.5 ? progress * 2 : 2 - progress * 2)
    }

    private func morphedGradient(stopsA: [Gradient.Stop], stopsB: [Gradient.Stop]?, mix: CGFloat) -> Gradient {
        guard let stopsB, stopsB.count == stopsA.count else {
            return Gradient(stops: stopsA)
        }

        let stops = zip(stopsA, stopsB).map { from, to in
            Gradient.Stop(color: .interpolate(from: from.color, to: to.color, value: Double(mix)), location: from.location)
        }
        return Gradient(stops: stops)
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    ZStack {
        Color(white: 0.04).ignoresSafeArea()
        AngularGlowBorder()
            .frame(width: 400, height: 200)
    }
}
#endif // DEBUG
