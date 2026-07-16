//
//  TangemPayAddCardView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct TangemPayAddCardView: View {
    var body: some View {
        DesignSystem.Icons.SignPlus.regular16.image
            .renderingMode(.template)
            .foregroundStyle(DesignSystem.Color.iconTertiary)
            .frame(
                width: 56,
                height: 40
            )
            .background(DesignSystem.Color.bgOpaquePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    TangemPayAddCardView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Color.bgPrimary)
}
#endif // DEBUG
