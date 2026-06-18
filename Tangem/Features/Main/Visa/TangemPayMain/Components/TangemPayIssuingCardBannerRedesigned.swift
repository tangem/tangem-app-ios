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
        HStack(alignment: .top, spacing: 12) {
            Assets.clock32.image
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .foregroundStyle(DesignSystem.Color.textPrimary)

            VStack(alignment: .leading, spacing: 0) {
                Text(Localization.tangempayIssuingNewDigitalCardTitle)
                    .font(DesignSystem.Font.bodyMediumToken)
                    .foregroundStyle(DesignSystem.Color.textPrimary)

                Text(Localization.tangempayReissueCardInProgressDescription)
                    .font(DesignSystem.Font.captionMediumToken)
                    .foregroundStyle(DesignSystem.Color.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    DesignSystem.Color.bgOpaqueSecondary
                        .shadow(.inner(color: .white.opacity(0.6), radius: 10))
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(DesignSystem.Color.borderSecondary, lineWidth: 1)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    TangemPayIssuingCardBannerRedesigned()
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Color.bgPrimary)
}
#endif // DEBUG
