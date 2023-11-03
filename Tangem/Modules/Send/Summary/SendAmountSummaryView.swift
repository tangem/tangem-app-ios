//
//  SendAmountSummaryView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

class SendAmountSummaryViewModel: Identifiable {
    let amount: String
    let amountFiat: String
    let tokenIconName: String
    let tokenIconURL: URL?
    let tokenIconCustomTokenColor: Color?
    let tokenIconBlockchainIconName: String?
    let isCustomToken: Bool

    init(
        amount: String,
        amountFiat: String,
        tokenIconName: String,
        tokenIconURL: URL?,
        tokenIconCustomTokenColor: Color?,
        tokenIconBlockchainIconName: String?,
        isCustomToken: Bool

    ) {
        self.amount = amount
        self.amountFiat = amountFiat
        self.tokenIconName = tokenIconName
        self.tokenIconURL = tokenIconURL
        self.tokenIconCustomTokenColor = tokenIconCustomTokenColor
        self.tokenIconBlockchainIconName = tokenIconBlockchainIconName
        self.isCustomToken = isCustomToken
    }
}

struct SendAmountSummaryView: View {
    let viewModel: SendAmountSummaryViewModel

    private let iconSize = CGSize(bothDimensions: 36)

    var body: some View {
        GroupedSection([viewModel]) { viewModel in
            VStack(alignment: .leading, spacing: 12) {
                Text(Localization.sendAmountLabel)
                    .style(Fonts.Regular.caption1, color: Colors.Text.secondary)

                HStack(spacing: 0) {
                    TokenIcon(
                        name: viewModel.tokenIconName,
                        imageURL: viewModel.tokenIconURL,
                        customTokenColor: viewModel.tokenIconCustomTokenColor,
                        blockchainIconName: viewModel.tokenIconBlockchainIconName,
                        isCustom: viewModel.isCustomToken,
                        size: iconSize
                    )
                    .padding(.trailing, 12)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(viewModel.amount)
                            .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)

                        Text(viewModel.amountFiat)
                            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    }
                    .truncationMode(.middle)
                    .lineLimit(1)

                    Spacer(minLength: 0)
                }
            }
            .padding(.vertical, 16)
        }
        .horizontalPadding(14)
        .separatorStyle(.single)
    }
}

#Preview {
    GroupedScrollView {
        SendAmountSummaryView(
            viewModel: SendAmountSummaryViewModel(
                amount: "100.00 USDT",
                amountFiat: "99.98$",
                tokenIconName: "tether",
                tokenIconURL: TokenIconURLBuilder().iconURL(id: "tether"),
                tokenIconCustomTokenColor: nil,
                tokenIconBlockchainIconName: "ethereum.fill",
                isCustomToken: false
            )
        )

        SendAmountSummaryView(
            viewModel: SendAmountSummaryViewModel(
                amount: "100 000 000 000 000 000 000 000 000 000 000.00 SOL",
                amountFiat: "999 999 999 999 999 999 999 999 999 999 999 999 999.98$",
                tokenIconName: "optimism",
                tokenIconURL: TokenIconURLBuilder().iconURL(id: "solana"),
                tokenIconCustomTokenColor: nil,
                tokenIconBlockchainIconName: nil,
                isCustomToken: false
            )
        )
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}
