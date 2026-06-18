//
//  TangemPayIssuingCardBannerRedesigned.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization

struct TangemPayIssuingCardBannerRedesigned: View {
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Tokens.Spacing.s150) {
            Assets.clock32.image
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: DesignSystem.Tokens.Size.s250, height: DesignSystem.Tokens.Size.s250)
                .foregroundStyle(DesignSystem.Tokens.Theme.Text.primary)

            VStack(alignment: .leading, spacing: 0) {
                Text(Localization.tangempayIssuingNewDigitalCardTitle)
                    .font(DesignSystem.Tokens.Font.Body.medium)
                    .foregroundStyle(DesignSystem.Tokens.Theme.Text.primary)

                Text(Localization.tangempayReissueCardInProgressDescription)
                    .font(DesignSystem.Tokens.Font.Caption.medium)
                    .foregroundStyle(DesignSystem.Tokens.Theme.Text.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(DesignSystem.Tokens.Spacing.s200)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: DesignSystem.Tokens.CornerRadius._250, style: .continuous)
                .fill(
                    DesignSystem.Tokens.Theme.Bg.Opaque.secondary
                        .shadow(.inner(color: .white.opacity(0.6), radius: 10))
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: DesignSystem.Tokens.CornerRadius._250, style: .continuous)
                .stroke(DesignSystem.Tokens.Theme.Border.secondary, lineWidth: DesignSystem.Tokens.BorderWidth.sm)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    TangemPayIssuingCardBannerRedesigned()
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Tokens.Theme.Bg.primary)
}
#endif // DEBUG
