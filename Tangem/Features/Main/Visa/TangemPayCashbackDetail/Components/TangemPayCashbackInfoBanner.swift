//
//  TangemPayCashbackInfoBanner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets
import TangemLocalization

struct TangemPayCashbackInfoBanner: View {
    let banner: TangemPayCashbackDetailViewData.Banner

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            DesignSystem.Icons.Info.regular20.image
                .renderingMode(.template)
                .foregroundStyle(iconColor)

            message
                .style(DesignSystem.Font.subheadingMediumToken, color: textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Content

private extension TangemPayCashbackInfoBanner {
    @ViewBuilder
    var message: some View {
        switch banner {
        case .deposit(let formattedAmount, let monthName, let payoutDate):
            SensitiveText(
                builder: { Localization.tangempayCashbackDepositBanner($0, monthName, payoutDate) },
                sensitive: formattedAmount
            )

        case .refund:
            Text(Localization.tangempayCashbackRefundBanner)
        }
    }

    var textColor: Color {
        switch banner {
        case .deposit: DesignSystem.Color.textStatusInfo
        case .refund: DesignSystem.Color.textStatusError
        }
    }

    var iconColor: Color {
        switch banner {
        case .deposit: DesignSystem.Color.iconStatusInfo
        case .refund: DesignSystem.Color.iconStatusError
        }
    }

    var backgroundColor: Color {
        switch banner {
        case .deposit: DesignSystem.Color.bgStatusInfoSubtle
        case .refund: DesignSystem.Color.bgStatusErrorSubtle
        }
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 12) {
        TangemPayCashbackInfoBanner(
            banner: .deposit(formattedAmount: "$22.54", monthName: "June", payoutDate: "July 5")
        )

        TangemPayCashbackInfoBanner(banner: .refund)
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}
