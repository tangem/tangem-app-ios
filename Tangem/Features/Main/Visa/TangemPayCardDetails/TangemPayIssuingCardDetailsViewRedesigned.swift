//
//  TangemPayIssuingCardDetailsViewRedesigned.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct TangemPayIssuingCardDetailsViewRedesigned: View {
    var body: some View {
        Assets.Visa.cardIssuing.image
            .resizable()
            .aspectRatio(Constants.plasticCardStandardWidthToHeightRatio, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Tokens.CornerRadius._250, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DesignSystem.Tokens.CornerRadius._250, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: DesignSystem.Tokens.BorderWidth.sm)
                    .allowsHitTesting(false)
            }
    }
}

private extension TangemPayIssuingCardDetailsViewRedesigned {
    enum Constants {
        static let plasticCardStandardWidthToHeightRatio = 1.586
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    TangemPayIssuingCardDetailsViewRedesigned()
        .padding(DesignSystem.Tokens.Spacing.s200)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Tokens.Theme.Bg.primary)
}
#endif // DEBUG
