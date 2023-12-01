//
//  RoundedBackgroundModifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct RoundedBackgroundModifier: ViewModifier {
    let verticalPadding: CGFloat
    let horizontalPadding: CGFloat
    let backgroundColor: Color
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(.vertical, verticalPadding)
            .padding(.horizontal, horizontalPadding)
            .background(backgroundColor)
            .cornerRadiusContinuous(cornerRadius)
    }
}

extension View {
    func roundedBackground(with color: Color, padding: CGFloat, radius: CGFloat) -> some View {
        modifier(
            RoundedBackgroundModifier(
                verticalPadding: padding,
                horizontalPadding: padding,
                backgroundColor: color,
                cornerRadius: radius
            )
        )
    }

    func defaultRoundedBackground(with color: Color = Colors.Background.primary) -> some View {
        modifier(
            RoundedBackgroundModifier(
                verticalPadding: 12,
                horizontalPadding: 14,
                backgroundColor: color,
                cornerRadius: 14
            )
        )
    }
}
