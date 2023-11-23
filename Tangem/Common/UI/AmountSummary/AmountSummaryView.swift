//
//  AmountSummaryView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct AmountSummaryView: View {
    let data: AmountSummaryViewData

    private let iconSize = CGSize(bothDimensions: 36)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.sendAmountLabel)
                .style(Fonts.Regular.footnote, color: Colors.Text.secondary)

            HStack(spacing: 0) {
                TokenIcon(
                    tokenIconInfo: TokenIconInfo(
                        name: data.tokenIconName,
                        blockchainIconName: data.tokenIconBlockchainIconName,
                        imageURL: data.tokenIconURL,
                        isCustom: data.isCustomToken,
                        customTokenColor: data.tokenIconCustomTokenColor
                    ),
                    size: iconSize
                )
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
    GroupedScrollView(spacing: 14) {
        GroupedSection([
            AmountSummaryViewData(
                amount: "100.00 USDT",
                amountFiat: "99.98$",
                tokenIconName: "tether",
                tokenIconURL: TokenIconURLBuilder().iconURL(id: "tether"),
                tokenIconCustomTokenColor: nil,
                tokenIconBlockchainIconName: "ethereum.fill",
                isCustomToken: false
            ),
        ]) {
            AmountSummaryView(data: $0)
        }
        .interSectionPadding(12)
        .verticalPadding(0)

        GroupedSection([
            AmountSummaryViewData(
                amount: "100 000 000 000 000 000 000 000 000 000 000.00 SOL",
                amountFiat: "999 999 999 999 999 999 999 999 999 999 999 999 999.98$",
                tokenIconName: "optimism",
                tokenIconURL: TokenIconURLBuilder().iconURL(id: "solana"),
                tokenIconCustomTokenColor: nil,
                tokenIconBlockchainIconName: nil,
                isCustomToken: false
            ),
        ]) {
            AmountSummaryView(data: $0)
        }
        .interSectionPadding(12)
        .verticalPadding(0)
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}
