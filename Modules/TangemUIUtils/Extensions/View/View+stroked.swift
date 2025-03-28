//
//  View+stroked.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    /// Strokes any view. Uses strokeBorder, so adjust your view's size accordingly
    func stroked(color: Color, cornerRadius: CGFloat, lineWidth: CGFloat) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(color, lineWidth: lineWidth)
        )
    }
}
