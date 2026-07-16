//
//  EmptyTokenGlyph.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

/// The empty-currency glyph shown when a row has no token icon (e.g. the "Other" bucket).
struct EmptyTokenGlyph: View {
    let size: CGFloat

    var body: some View {
        Assets.emptyTokenList.image
            .resizable()
            .scaledToFit()
            .foregroundStyle(DesignSystem.Color.iconPrimary)
            .frame(width: size, height: size)
    }
}
