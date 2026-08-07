//
//  View+style.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public extension View {
    func style(_ font: Font, color: Color) -> some View {
        self
            .font(font)
            .foregroundStyle(color)
    }

    func style(_ token: TangemTypographyToken, color: Color) -> some View {
        font(token: token)
            .foregroundStyle(color)
    }

    func font(token: TangemTypographyToken) -> some View {
        modifier(TangemTypographyTokenModifier(token: token))
    }
}

private struct TangemTypographyTokenModifier: ViewModifier {
    let token: TangemTypographyToken
    @ScaledMetric private var scaledSize: CGFloat

    init(token: TangemTypographyToken) {
        self.token = token
        _scaledSize = ScaledMetric(wrappedValue: token.fontSize, relativeTo: token.relativeTo)
    }

    func body(content: Content) -> some View {
        content
            .font(.system(size: scaledSize, weight: token.fontWeight))
            .lineSpacing(token.lineSpacing)
            .tracking(token.tracking)
    }
}
