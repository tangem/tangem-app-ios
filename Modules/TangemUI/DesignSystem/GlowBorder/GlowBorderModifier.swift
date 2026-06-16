//
//  GlowBorderModifier.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

// MARK: - GlowBorderModifier

/// Adds a glowing animated border around the content.
///
/// Performance strategy:
/// - Blur layers are rasterized once via `drawingGroup()` and never re-rendered.
/// - Rotation is driven by a single `withAnimation(.linear)` — Core Animation rotates the
///   cached Metal texture on the GPU with zero per-frame CPU work.
/// - Opacity is sampled at 5 fps via `Timer` and smoothly interpolated by CA between ticks.
/// - The gradient is rendered in an oversized square (side = diagonal of the banner) so that
///   rotating it never exposes empty corners — it's then clipped back to the banner shape.
struct GlowBorderModifier: ViewModifier {
    let effect: GlowBorderEffect
    let cornerRadius: CGFloat

    @State private var isActive = false
    @State private var rotation: CGFloat = 0
    @State private var glowOpacity: CGFloat = 1.0
    @State private var timerSubscription: AnyCancellable?

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius)

        content
            .background(effect.backgroundColor, in: shape)
            .overlay { staticBorderOverlay(shape: shape) }
            .overlay { animatedGlowOverlay(shape: shape) }
            .compositingGroup()
            .onAppear { activate() }
            .onDisappear { deactivate() }
            .onReceive(backgroundNotification) { _ in deactivate() }
            .onReceive(foregroundNotification) { _ in activate() }
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

    func animatedGlowOverlay(shape: RoundedRectangle) -> some View {
        GeometryReader { geometry in
            // Oversized square ensures no empty corners appear during rotation
            let diagonal = hypot(geometry.size.width, geometry.size.height)

            GlowGradientOverlay(colors: effect.glowColors, cornerRadius: cornerRadius)
                .equatable()
                .frame(width: diagonal, height: diagonal)
                .drawingGroup()
                .rotationEffect(.degrees(rotation))
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        }
        .clipShape(shape)
        .opacity(effect == .none ? 0 : glowOpacity)
        .allowsHitTesting(false)
    }
}

// MARK: - Lifecycle & Animation

private extension GlowBorderModifier {
    var backgroundNotification: NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
    }

    var foregroundNotification: NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
    }

    func activate() {
        guard effect != .none else { return }

        isActive = true
        startRotation()
        startOpacityTimer()
    }

    func deactivate() {
        isActive = false
        timerSubscription = nil
    }

    func startRotation() {
        rotation = 0
        withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
            rotation = 360
        }
    }

    /// Fires at 5 fps — just enough to sample the opacity keyframe curve.
    /// CA smoothly interpolates between samples via `withAnimation(.linear(duration: 0.2))`.
    /// The subscription is held in `timerSubscription` and cancelled on deactivate,
    /// so the timer never wakes the run loop when the glow is inactive.
    func startOpacityTimer() {
        timerSubscription = Timer.publish(every: 0.2, on: .main, in: .common)
            .autoconnect()
            .sink { date in
                let newOpacity = interpolatedOpacity(from: date.timeIntervalSinceReferenceDate)
                withAnimation(.linear(duration: 0.2)) {
                    glowOpacity = newOpacity
                }
            }
    }
}

// MARK: - Opacity Keyframes

private extension GlowBorderModifier {
    var duration: CGFloat { 6.4 }

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
        guard effect != .none else { return 0 }

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
