//
//  GlowBorderModifier.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

// MARK: - GlowBorderModifier

/// Adds a glowing animated border around the content.
///
/// Performance & correctness strategy:
/// - Blur layers are rasterized once via `drawingGroup()` and never re-rendered.
/// - Both rotation and opacity are derived from wall-clock time inside a single
///   `TimelineView(.animation)`. Driving the cycle from absolute time — rather than a
///   `repeatForever` animation started in `onAppear` — means it can never stack or
///   accelerate across appear/disappear (e.g. push-pop navigation), and the timeline
///   pauses itself when the view is off-screen or the app is backgrounded.
/// - The gradient is rendered in an oversized square (side = diagonal of the banner) so that
///   rotating it never exposes empty corners — it's then clipped back to the banner shape.
struct GlowBorderModifier: ViewModifier {
    let effect: GlowBorderEffect
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius)

        content
            .background(effect.backgroundColor, in: shape)
            .overlay { staticBorderOverlay(shape: shape) }
            .overlay { animatedGlowOverlay(shape: shape) }
            .compositingGroup()
    }
}

// MARK: - Subviews

private extension GlowBorderModifier {
    func staticBorderOverlay(shape: RoundedRectangle) -> some View {
        shape
            .strokeBorder(Color.Tangem.Border.Neutral.banner, lineWidth: SizeUnit.half.value)
            .blur(radius: SizeUnit.x8.value)
            .drawingGroup()
            .clipShape(shape)
            .allowsHitTesting(false)
    }

    @ViewBuilder
    func animatedGlowOverlay(shape: RoundedRectangle) -> some View {
        if effect == .none {
            EmptyView()
        } else {
            GeometryReader { geometry in
                // Oversized square ensures no empty corners appear during rotation
                let diagonal = hypot(geometry.size.width, geometry.size.height)

                TimelineView(.animation) { context in
                    let elapsed = context.date.timeIntervalSinceReferenceDate

                    GlowGradientOverlay(colors: effect.glowColors, cornerRadius: cornerRadius)
                        .equatable()
                        .frame(width: diagonal, height: diagonal)
                        .drawingGroup()
                        .rotationEffect(.degrees(rotation(at: elapsed)))
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .opacity(interpolatedOpacity(from: elapsed))
                }
            }
            .clipShape(shape)
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Animation Curve

private extension GlowBorderModifier {
    var duration: Double { 6.4 }

    func rotation(at elapsed: TimeInterval) -> Double {
        let cycleProgress = elapsed.truncatingRemainder(dividingBy: duration) / duration
        return cycleProgress * 360
    }

    var opacityKeyframes: [(time: Double, opacity: Double)] {
        [
            (0.0, 1.0),
            (2.0, 0.3),
            (3.5, 0.04),
            (3.9, 0.5),
            (6.4, 1.0),
        ]
    }

    func interpolatedOpacity(from elapsed: TimeInterval) -> Double {
        let cycleTime = elapsed.truncatingRemainder(dividingBy: duration)

        for index in 0 ..< opacityKeyframes.count - 1 {
            let current = opacityKeyframes[index]
            let next = opacityKeyframes[index + 1]

            if cycleTime >= current.time, cycleTime < next.time {
                let segmentDuration = next.time - current.time
                let segmentProgress = (cycleTime - current.time) / segmentDuration
                return current.opacity + (next.opacity - current.opacity) * segmentProgress
            }
        }

        return opacityKeyframes.last?.opacity ?? 1.0
    }
}

// MARK: - GlowGradientOverlay

/// The gradient + blur content that gets rasterized once and then rotated by CA.
/// Conforms to `Equatable` so `.equatable()` prevents SwiftUI from re-evaluating the body
/// when the parent re-renders (inputs never change after creation).
private struct GlowGradientOverlay: View, Equatable {
    let colors: [Color]
    let cornerRadius: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius)
        let gradient = AngularGradient(colors: colors, center: .center)

        ZStack {
            shape
                .fill(gradient)
                .blur(radius: SizeUnit.x10.value)
                .opacity(0.15)

            shape
                .strokeBorder(gradient, lineWidth: SizeUnit.x2.value)
                .blur(radius: SizeUnit.x6.value)
        }
        .clipShape(shape)
    }
}

// MARK: - View Extension

public extension View {
    func glowBorder(
        effect: GlowBorderEffect,
        cornerRadius: CGFloat = SizeUnit.x6.value
    ) -> some View {
        modifier(GlowBorderModifier(effect: effect, cornerRadius: cornerRadius))
    }
}
