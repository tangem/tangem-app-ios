//
//  GlowBorderModifier.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct GlowBorderModifier: ViewModifier {
    let effect: GlowBorderEffect
    let cornerRadius: CGFloat

    @State private var isActive: Bool = false

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius)

        TimelineView(.animation(paused: !isActive || effect == .none)) { timeline in
            let elapsed = timeline.date.timeIntervalSinceReferenceDate
            let rotation = rotationDegrees(from: elapsed)
            let glowOpacity = interpolatedOpacity(from: elapsed)

            makeBody(content: content, shape: shape, rotation: rotation, glowOpacity: glowOpacity)
        }
    }

    private func makeBody(
        content: Content,
        shape: RoundedRectangle,
        rotation: CGFloat,
        glowOpacity: CGFloat
    ) -> some View {
        let gradient = AngularGradient(
            colors: effect.glowColors,
            center: .center,
            angle: .degrees(rotation)
        )

        return content
            .background(effect.backgroundColor, in: shape)
            .overlay {
                ZStack {
                    shape
                        .strokeBorder(Color.Tangem.Border.Neutral.banner, lineWidth: SizeUnit.half.value)
                        .blur(radius: SizeUnit.x8.value)

                    shape
                        .strokeBorder(gradient, lineWidth: SizeUnit.x2.value)
                        .blur(radius: SizeUnit.x6.value)
                        .opacity(glowOpacity)
                }
                .onReceive(
                    NotificationCenter.default
                        .publisher(for: UIApplication.didEnterBackgroundNotification)
                ) { _ in
                    isActive = false
                }
                .onReceive(
                    NotificationCenter.default
                        .publisher(for: UIApplication.willEnterForegroundNotification)
                ) { _ in
                    isActive = true
                }
                .onAppear {
                    isActive = true
                }
                .clipShape(shape)
            }
            .drawingGroup()
            .compositingGroup()
    }
}

extension View {
    func glowBorder(
        effect: GlowBorderEffect,
        cornerRadius: CGFloat = SizeUnit.x6.value
    ) -> some View {
        modifier(GlowBorderModifier(effect: effect, cornerRadius: cornerRadius))
    }
}

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

    func rotationDegrees(from elapsed: TimeInterval) -> Double {
        let progress = elapsed.truncatingRemainder(dividingBy: duration) / duration
        return progress * 360
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
