//
//  AmountSummaryView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUIUtils
import TangemUI

struct AmountSummaryView: View {
    let data: AmountSummaryViewData

    private let iconSize = CGSize(bothDimensions: 36)

    init(data: AmountSummaryViewData) {
        self.data = data
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ExpressCurrencyDefaultHeaderView(headerType: data.headerType)

            HStack(spacing: 0) {
                TokenIcon(tokenIconInfo: data.tokenIconInfo, size: iconSize)
                    .padding(.trailing, 12)

                VStack(alignment: .leading, spacing: 6) {
                    Text(data.amount)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)

                    Text(data.amountFiat)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                }
                .truncationMode(.middle)
                .lineLimit(1)

                Spacer(minLength: 0)
            }
        }
    }
}

#Preview {
    GroupedScrollView(contentType: .lazy(alignment: .leading, spacing: 14)) {
        GroupedSection(
            [
                AmountSummaryViewData(
                    title: Localization.commonAmount,
                    amount: "100.00 USDT",
                    amountFiat: "99.98$",
                    tokenIconInfo: .init(
                        name: "tether",
                        blockchainIconAsset: Tokens.ethereumFill,
                        imageURL: IconURLBuilder().tokenIconURL(id: "tether"),
                        isCustom: false,
                        customTokenColor: nil
                    )
                ),
            ]
        ) {
            AmountSummaryView(data: $0)
        }
        .innerContentPadding(12)

        GroupedSection([
            AmountSummaryViewData(
                title: Localization.commonAmount,
                amount: "100 000 000 000 000 000 000 000 000 000 000.00 SOL",
                amountFiat: "999 999 999 999 999 999 999 999 999 999 999 999 999.98$",
                tokenIconInfo: .init(
                    name: "optimism",
                    blockchainIconAsset: nil,
                    imageURL: IconURLBuilder().tokenIconURL(id: "solana"),
                    isCustom: false,
                    customTokenColor: nil
                )
            ),
        ]) {
            AmountSummaryView(data: $0)
        }
        .innerContentPadding(12)
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}
