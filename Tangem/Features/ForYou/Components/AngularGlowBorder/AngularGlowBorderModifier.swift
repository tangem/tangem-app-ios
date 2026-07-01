//
//  AngularGlowBorderModifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//
//  Animated angular-gradient glow border, applied as an overlay via `.angularGlowBorder()`.
//  Non-obvious bit: seam rotation and the vertical squish are decoupled — the squish stays
//  axis-aligned and never rotates with the seam, which is what makes the radius morph visible.
//

import SwiftUI
import TangemUI

// MARK: - View extension

extension View {
    func angularGlowBorder(config: AngularGlowBorderModifier.Config = .init()) -> some View {
        modifier(AngularGlowBorderModifier(config: config))
    }
}

struct AngularGlowBorderModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Margin so the centered stroke's clipped outer half (and the blur falloff feeding
    /// inward) is fully rendered before the rounded-box clip cuts the outer half.
    private let margin: CGFloat = 64

    private let config: Config

    init(config: Config) {
        self.config = config
    }

    func body(content: Content) -> some View {
        content.overlay {
            GeometryReader { proxy in
                canvas(width: proxy.size.width, height: proxy.size.height)
            }
        }
    }
}

// MARK: - Rendering

private extension AngularGlowBorderModifier {
    @ViewBuilder
    func canvas(width w: CGFloat, height h: CGFloat) -> some View {
        if reduceMotion {
            // Reduce Motion: freeze to a static frame — no rotation/breathing/palette morph, and
            // no per-frame redraw. Phase 0 keeps the shape at its widest (least distortion).
            canvasContent(width: w, height: h, phase: 0, mix: 0)
        } else {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                canvasContent(width: w, height: h, phase: phaseAngle(at: t), mix: morphMix(at: t))
            }
        }
    }

    func canvasContent(width w: CGFloat, height h: CGFloat, phase: Double, mix: CGFloat) -> some View {
        let m = margin
        let scheme = colorScheme

        return Canvas { context, size in
            draw(into: &context, size: size, phase: phase, mix: mix, scheme: scheme)
        }
        .frame(width: w + 2 * m, height: h + 2 * m) // oversized canvas (holds outer half + blur)
        .frame(width: w, height: h) // layout footprint = the box; canvas overflows centered
        .clipShape(RoundedRectangle(cornerRadius: config.cornerRadius, style: .continuous)) // clip AFTER blur
    }

    func draw(into context: inout GraphicsContext, size: CGSize, phase: Double, mix: CGFloat, scheme: ColorScheme) {
        let box = CGRect(x: margin, y: margin, width: size.width - 2 * margin, height: size.height - 2 * margin)
        let gradient = config.palette.gradient(mix: mix, scheme: scheme)
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

    func phaseAngle(at time: TimeInterval) -> Double {
        let f = time.truncatingRemainder(dividingBy: config.duration) / config.duration
        return config.startAngle + (config.clockwise ? 1 : -1) * config.easing.value(f) * 360
    }

    /// Radius morph: horizontal radius breathes with the phase (wide W/2 @ 0°/180°,
    /// narrow W/8 @ 90°/270°); ry stays fixed at H/2.
    func horizontalRadius(box: CGRect, phase: Double) -> CGFloat {
        let maxRx = box.width / 2
        let minRx = box.width / 8
        let mid = (maxRx + minRx) / 2
        let amp = max(0, (maxRx - minRx) / 2)
        return mid + amp * CGFloat(cos(2 * phase * .pi / 180))
    }
}

// MARK: - Gradient palette morph

private extension AngularGlowBorderModifier {
    /// Ping-pong 0→1→0 over `morphDuration`; returns 0 (no morph) when there is no B palette.
    func morphMix(at time: TimeInterval) -> CGFloat {
        guard config.palette.canMorph, config.morphDuration > 0 else { return 0 }
        let progress = time.truncatingRemainder(dividingBy: config.morphDuration) / config.morphDuration
        return CGFloat(progress < 0.5 ? progress * 2 : 2 - progress * 2)
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
