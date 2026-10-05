//
//  MaterialSurface.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import BlurSwiftUI

public enum TangemMaterialStyle: Sendable, Hashable {
    case `default`
    case inverted
}

public extension View {
    /// - Parameter prefersInset: Draws a flat inset fill instead of glass on iOS 26, which renders glass laid over
    ///   a sheet's own glass almost invisibly. iOS 27 and versions below 26 ignore it.
    func tangemMaterialSurface(
        in shape: some InsettableShape,
        style: TangemMaterialStyle = .default,
        isVisible: Bool = true,
        interactive: Bool = false,
        shadow: TangemShadowToken? = DesignSystem.Shadow.button,
        prefersInset: Bool = false
    ) -> some View {
        modifier(
            MaterialSurface(
                shape: shape,
                style: style,
                isVisible: isVisible,
                interactive: interactive,
                shadow: shadow,
                prefersInset: prefersInset
            )
        )
    }
}

struct MaterialSurface<S: InsettableShape>: ViewModifier {
    let shape: S
    let style: TangemMaterialStyle
    let isVisible: Bool
    let interactive: Bool
    let shadow: TangemShadowToken?
    let prefersInset: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 27.0, *) {
            glass(content)
        } else if #available(iOS 26.0, *) {
            // One view tree for both, so switching to the inset animates instead of rebuilding the content.
            glass(content, drawsGlass: !prefersInset)
                .background { inset }
                .animation(.default, value: prefersInset)
        } else {
            fallback(content)
                .animation(.default, value: isVisible)
        }
    }

    @available(iOS 26.0, *)
    private func glass(_ content: some View, drawsGlass: Bool = true) -> some View {
        content
            .glassEffect(
                isVisible && drawsGlass
                    ? .regular
                    .tint(glassTint)
                    .interactive(interactive)
                    : .identity,
                in: shape
            )
            .background { glassShadow.opacity(drawsGlass ? 1 : 0) }
            .animation(.default, value: isVisible)
    }

    private var inset: some View {
        shape
            .fill(DesignSystem.Color.bgTransparentPrimary)
            .opacity(isVisible && prefersInset ? 1 : 0)
            .animation(.default, value: isVisible)
    }

    @ViewBuilder
    private func fallback(_ content: Content) -> some View {
        let surface = content
            .background { blurBackground.opacity(isVisible ? 1 : 0) }
            .overlay { borderStroke.opacity(isVisible ? 1 : 0) }

        if let shadow, isVisible {
            surface.tangemShadow(shadow)
        } else {
            surface
        }
    }

    @ViewBuilder
    private var glassShadow: some View {
        if let shadow, isVisible {
            shape
                .fill(shadow.color)
                .blur(radius: shadow.blur)
                .offset(x: shadow.offsetX, y: shadow.offsetY)
        }
    }

    private var blurBackground: some View {
        VariableBlur(direction: .down)
            .maximumBlurRadius(materialSurfaceBlurRadius)
            .dimmingTintColor(nil)
            .dimmingAlpha(.constant(alpha: 0))
            .dimmingOvershoot(nil)
            .overlay { shape.fill(fillColor) }
            .clipShape(shape)
    }

    private var borderStroke: some View {
        shape
            .strokeBorder(
                LinearGradient(
                    colors: borderColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }

    private var fillColor: Color {
        switch style {
        case .default: DesignSystem.Color.materialFillBlur
        case .inverted: DesignSystem.Color.materialInvertedFillBlur
        }
    }

    private var borderColors: [Color] {
        switch style {
        case .default:
            [
                DesignSystem.Color.materialBorderStart,
                DesignSystem.Color.materialBorderMid,
                DesignSystem.Color.materialBorderEnd,
            ]
        case .inverted:
            [
                DesignSystem.Color.materialInvertedBorderStart,
                DesignSystem.Color.materialInvertedBorderMid,
                DesignSystem.Color.materialInvertedBorderEnd,
            ]
        }
    }

    private var glassTint: Color? {
        switch style {
        case .default: nil
        case .inverted: DesignSystem.Color.bgInverse.opacity(0.7)
        }
    }
}

private let materialSurfaceBlurRadius: CGFloat = 10
