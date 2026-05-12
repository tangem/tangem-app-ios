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
        font(token)
            .foregroundStyle(color)
    }
}
