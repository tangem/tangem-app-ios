//
//  RoundedBackgroundModifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct RoundedBackgroundModifier: ViewModifier {
    let verticalPadding: CGFloat
    let horizontalPadding: CGFloat
    let backgroundColor: Color
    var cornerRadius: CGFloat = 14
    let geometryEffect: GeometryEffectPropertiesModel?

    func body(content: Content) -> some View {
        content
            .padding(.vertical, verticalPadding)
            .padding(.horizontal, horizontalPadding)
            .background(
                backgroundColor
                    .matchedGeometryEffect(geometryEffect)
            )
            .cornerRadiusContinuous(cornerRadius)
    }
}

public extension View {
    static var defaultCornerRadius: CGFloat { 14 }
    static var defaultVerticalPadding: CGFloat { 12 }
    static var defaultHorizontalPadding: CGFloat { 14 }

    func roundedBackground(
        with color: Color,
        padding: CGFloat,
        radius: CGFloat = Self.defaultCornerRadius,
        geometryEffect: GeometryEffectPropertiesModel? = .none
    ) -> some View {
        modifier(
            RoundedBackgroundModifier(
                verticalPadding: padding,
                horizontalPadding: padding,
                backgroundColor: color,
                cornerRadius: radius,
                geometryEffect: geometryEffect
            )
        )
    }

    func roundedBackground(
        with color: Color,
        verticalPadding: CGFloat,
        horizontalPadding: CGFloat,
        radius: CGFloat = Self.defaultCornerRadius,
        geometryEffect: GeometryEffectPropertiesModel? = .none
    ) -> some View {
        modifier(
            RoundedBackgroundModifier(
                verticalPadding: verticalPadding,
                horizontalPadding: horizontalPadding,
                backgroundColor: color,
                cornerRadius: radius,
                geometryEffect: geometryEffect
            )
        )
    }

    func defaultRoundedBackground(
        with color: Color = Colors.Background.primary,
        verticalPadding: CGFloat = Self.defaultVerticalPadding,
        horizontalPadding: CGFloat = Self.defaultHorizontalPadding,
        cornerRadius: CGFloat = Self.defaultCornerRadius,
        geometryEffect: GeometryEffectPropertiesModel? = .none
    ) -> some View {
        modifier(
            RoundedBackgroundModifier(
                verticalPadding: verticalPadding,
                horizontalPadding: horizontalPadding,
                backgroundColor: color,
                cornerRadius: cornerRadius,
                geometryEffect: geometryEffect
            )
        )
    }
}
