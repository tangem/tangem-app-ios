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
            .foregroundStyle(DesignSystem.Tokens.Theme.Icon.tertiary)
            .frame(
                width: DesignSystem.Tokens.Size.s700,
                height: DesignSystem.Tokens.Size.s500
            )
            .background(DesignSystem.Tokens.Theme.Bg.Opaque.primary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Tokens.CornerRadius._075, style: .continuous))
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    TangemPayAddCardView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Tokens.Theme.Bg.primary)
}
#endif // DEBUG
