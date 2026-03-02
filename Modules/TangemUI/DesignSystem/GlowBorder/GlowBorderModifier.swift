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

    @State private var rotation: Double = 0

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius)

        makeBody(content: content, shape: shape)
    }

    private func makeBody(content: Content, shape: RoundedRectangle) -> some View {
        let gradient = AngularGradient(
            colors: effect.glowColors,
            center: .center,
            angle: .degrees(rotation)
        )

        let strokeAngle = switch effect {
        case .none:
            Angle.zero
        case .bannerMagic, .bannerCard, .bannerWarning:
            Angle.degrees(rotation)
        }

        let strokeGradient = AngularGradient(
            colors: effect.strokeGradientColors,
            center: .center,
            angle: strokeAngle
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

                    shape
                        .stroke(strokeGradient.opacity(0.3), lineWidth: SizeUnit.x1.value)
                }
                .onReceive(
                    NotificationCenter.default
                        .publisher(for: UIApplication.didEnterBackgroundNotification)
                ) { _ in
                    rotation = .zero
                }
                .onReceive(
                    NotificationCenter.default
                        .publisher(for: UIApplication.willEnterForegroundNotification)
                ) { _ in
                    runAnimation()
                }
                .onAppear {
                    runAnimation()
                }
                .clipShape(shape)
                .animation(
                    .linear(duration: 6).repeatForever(autoreverses: false),
                    value: rotation
                )
            }
            .drawingGroup()
            .compositingGroup()
    }

    private func runAnimation() {
        guard effect != .none else { return }
        rotation = 360
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
