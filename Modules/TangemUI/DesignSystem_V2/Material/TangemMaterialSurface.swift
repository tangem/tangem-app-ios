//
//  TangemMaterialSurface.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import BlurSwiftUI

public extension View {
    func tangemMaterialSurface(
        in shape: some InsettableShape,
        interactive: Bool = false,
        shadow: TangemShadowToken? = DesignSystem.Shadow.button
    ) -> some View {
        modifier(TangemMaterialSurface(shape: shape, interactive: interactive, shadow: shadow))
    }
}

struct TangemMaterialSurface<S: InsettableShape>: ViewModifier {
    let shape: S
    let interactive: Bool
    let shadow: TangemShadowToken?

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(
                    .regular
                        .tint(DesignSystem.Color.materialTintGlass)
                        .interactive(interactive),
                    in: shape
                )
        } else {
            fallback(content)
        }
    }

    @ViewBuilder
    private func fallback(_ content: Content) -> some View {
        let surface = content
            .background { blurBackground }
            .overlay { borderStroke }

        if let shadow {
            surface.tangemShadow(shadow)
        } else {
            surface
        }
    }

    private var blurBackground: some View {
        VariableBlur(direction: .down)
            .maximumBlurRadius(materialSurfaceBlurRadius)
            .dimmingTintColor(nil)
            .dimmingAlpha(.constant(alpha: 0))
            .dimmingOvershoot(nil)
            .overlay { shape.fill(DesignSystem.Color.materialFillBlur) }
            .clipShape(shape)
    }

    private var borderStroke: some View {
        shape
            .strokeBorder(
                LinearGradient(
                    colors: [
                        DesignSystem.Color.materialBorderStart,
                        DesignSystem.Color.materialBorderMid,
                        DesignSystem.Color.materialBorderEnd,
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
}

private let materialSurfaceBlurRadius: CGFloat = 10
