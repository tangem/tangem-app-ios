//
//  AngularGlowBorderModifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//
//  Animated angular-gradient glow border (v17) — applied as an overlay via `.angularGlowBorder()`.
//  Three stacked, blurred copies of one conic gradient. The color seam rotates 360° per
//  loop via the gradient angle, while the horizontal radius "breathes" (rxMorph: wide at
//  0°/180°, narrow at 90°/270°). Seam rotation and the vertical squish are decoupled — the
//  squish stays axis-aligned and never rotates with the seam, which is what makes the morph
//  visible. When a second palette is provided, the colors also ping-pong between the two
//  sets. Each layer is a centered stroke, blurred, then clipped to the rounded box.
//

import SwiftUI
import TangemUI

struct AngularGlowBorderModifier: ViewModifier {
    let config: Config

    /// Margin so the centered stroke's clipped outer half (and the blur falloff feeding
    /// inward) is fully rendered before the rounded-box clip cuts the outer half.
    private let margin: CGFloat = 64

    func body(content: Content) -> some View {
        content.overlay {
            GeometryReader { proxy in
                canvas(width: proxy.size.width, height: proxy.size.height)
            }
        }
    }
}

// MARK: - View extension

extension View {
    /// Overlays the animated angular-gradient glow border (v17) on the content.
    func angularGlowBorder(config: AngularGlowBorderModifier.Config = .init()) -> some View {
        modifier(AngularGlowBorderModifier(config: config))
    }
}

// MARK: - Rendering

private extension AngularGlowBorderModifier {
    func canvas(width w: CGFloat, height h: CGFloat) -> some View {
        let m = margin

        return TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let phase = phaseAngle(at: t)
            let mix = morphMix(at: t)

            Canvas { context, size in
                draw(into: &context, size: size, phase: phase, mix: mix)
            }
            .frame(width: w + 2 * m, height: h + 2 * m) // oversized canvas (holds outer half + blur)
            .frame(width: w, height: h) // layout footprint = the box; canvas overflows centered
            .clipShape(RoundedRectangle(cornerRadius: config.cornerRadius, style: .continuous)) // clip AFTER blur
        }
    }

    func draw(into context: inout GraphicsContext, size: CGSize, phase: Double, mix: CGFloat) {
        let box = CGRect(x: margin, y: margin, width: size.width - 2 * margin, height: size.height - 2 * margin)
        let gradient = morphedGradient(stopsA: config.stopsA, stopsB: config.stopsB, mix: mix)
        let rx = horizontalRadius(box: box, phase: phase)

        // draw bottom → top so layers[0] ends on top
        for layer in config.layers.reversed() {
            drawLayer(layer, into: &context, box: box, gradient: gradient, rx: rx, phase: phase)
        }
    }

    func drawLayer(
        _ layer: Config.BorderLayer,
        into context: inout GraphicsContext,
        box: CGRect,
        gradient: Gradient,
        rx: CGFloat,
        phase: Double
    ) {
        context.drawLayer { ctx in
            ctx.opacity = layer.opacity
            ctx.addFilter(.blur(radius: layer.blur))
            ctx.clip(to: ringPath(box: box, stroke: layer.stroke), style: FillStyle(eoFill: true))

            // axis-aligned vertical squish (radius morph); the seam rotates via the gradient
            // angle, decoupled from the squish so the morph stays visible
            ctx.translateBy(x: box.midX, y: box.midY)
            ctx.scaleBy(x: 1, y: rx > 0 ? box.height / 2 / rx : 1)

            let shading = GraphicsContext.Shading.conicGradient(
                gradient, center: .zero, angle: .degrees(config.seamOffset + phase)
            )
            ctx.fill(
                Path(CGRect(x: -4000, y: -4000, width: 8000, height: 8000)),
                with: shading
            )
        }
    }
}

// MARK: - Geometry

private extension AngularGlowBorderModifier {
    /// Centered even-odd stroke ring: outer = box + stroke/2, inner = box − stroke/2.
    func ringPath(box: CGRect, stroke: CGFloat) -> Path {
        let o = stroke / 2
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
        return ring
    }

    /// Seam rotation angle (degrees), eased over the loop.
    func phaseAngle(at time: TimeInterval) -> Double {
        let f = time.truncatingRemainder(dividingBy: config.duration) / config.duration
        return config.startAngle + (config.clockwise ? 1 : -1) * config.easing.value(f) * 360
    }

    /// v17 radius morph: horizontal radius breathes with the phase (wide W/2 @ 0°/180°,
    /// narrow W/8 @ 90°/270°); ry stays fixed at H/2.
    func horizontalRadius(box: CGRect, phase: Double) -> CGFloat {
        let maxRx = box.width / 2
        let minRx = box.width / 8
        let mid = (maxRx + minRx) / 2
        let amp = max(0, (maxRx - minRx) / 2)
        return mid + amp * CGFloat(cos(2 * phase * .pi / 180))
    }
}

// MARK: - Gradient palette morph (v17)

private extension AngularGlowBorderModifier {
    /// Ping-pong 0→1→0 over `morphDuration`; returns 0 (no morph) when there is no B palette.
    func morphMix(at time: TimeInterval) -> CGFloat {
        guard config.stopsB != nil, config.morphDuration > 0 else { return 0 }
        let progress = time.truncatingRemainder(dividingBy: config.morphDuration) / config.morphDuration
        return CGFloat(progress < 0.5 ? progress * 2 : 2 - progress * 2)
    }

    func morphedGradient(stopsA: [Gradient.Stop], stopsB: [Gradient.Stop]?, mix: CGFloat) -> Gradient {
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
        Color.clear
            .frame(width: 400, height: 200)
            .angularGlowBorder()
    }
}
#endif // DEBUG
