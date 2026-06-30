//
//  AngularGlowBorder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//
//  Animated angular-gradient glow border — SwiftUI port of the web rig (v10).
//  A centered, anisotropic conic gradient rotates 360° per loop. The border is three
//  stacked, blurred copies of that gradient (tight core → wide halo), each a centered
//  stroke on the box edge, blurred, then clipped to the rounded box. The rig's
//  "breathing" is intentionally not implemented — a uniform scale of an angular
//  gradient is invisible; only the anisotropy + rotation are rendered.
//

import SwiftUI

struct AngularGlowBorder: View {
    var config = Config()

    /// Margin so the centered stroke's clipped outer half (and the blur falloff feeding
    /// inward) is fully rendered before the rounded-box clip cuts the outer half.
    private let margin: CGFloat = 128

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

            Canvas { context, size in
                let box = CGRect(x: m, y: m, width: size.width - 2 * m, height: size.height - 2 * m)
                let gradient = Gradient(stops: config.stops)
                let anisotropy = config.anisotropy

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

                        // anisotropic conic, rotated about the box center
                        layerContext.translateBy(x: box.midX, y: box.midY)
                        layerContext.rotate(by: .degrees(phase))
                        layerContext.scaleBy(x: 1, y: anisotropy)

                        let shading = GraphicsContext.Shading.conicGradient(
                            gradient, center: .zero, angle: .degrees(config.seamOffset)
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
