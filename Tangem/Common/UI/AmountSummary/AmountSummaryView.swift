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

    private var namespace: Namespace.ID?
    private var titleNamespaceId: String?
    private var iconNamespaceId: String?
    private var amountNamespaceId: String?

    private let iconSize = CGSize(bothDimensions: 36)

    init(data: AmountSummaryViewData) {
        self.data = data
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(data.title)
                .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                .matchedGeometryEffect(id: titleNamespaceId, in: namespace)

            HStack(spacing: 0) {
                TokenIcon(tokenIconInfo: data.tokenIconInfo, size: iconSize)
                    .matchedGeometryEffect(id: iconNamespaceId, in: namespace)
                    .padding(.trailing, 12)

                VStack(alignment: .leading, spacing: 6) {
                    Text(data.amount)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
                        .matchedGeometryEffect(id: amountNamespaceId, in: namespace)

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

extension AmountSummaryView: Setupable {
    func setNamespace(_ namespace: Namespace.ID) -> Self {
        map { $0.namespace = namespace }
    }

    func setTitleNamespaceId(_ titleNamespaceId: String?) -> Self {
        map { $0.titleNamespaceId = titleNamespaceId }
    }

    func setIconNamespaceId(_ iconNamespaceId: String?) -> Self {
        map { $0.iconNamespaceId = iconNamespaceId }
    }

    func setAmountNamespaceId(_ amountNamespaceId: String?) -> Self {
        map { $0.amountNamespaceId = amountNamespaceId }
    }
}

#Preview {
    GroupedScrollView(spacing: 14) {
        GroupedSection(
            [
                AmountSummaryViewData(
                    title: Localization.sendAmountLabel,
                    amount: "100.00 USDT",
                    amountFiat: "99.98$",
                    tokenIconInfo: .init(
                        name: "tether",
                        blockchainIconName: "ethereum.fill",
                        imageURL: TokenIconURLBuilder().iconURL(id: "tether"),
                        isCustom: false,
                        customTokenColor: nil
                    )
                ),
            ]
        ) {
            AmountSummaryView(data: $0)
        }
        .interSectionPadding(12)
        .verticalPadding(0)

        GroupedSection([
            AmountSummaryViewData(
                title: Localization.sendAmountLabel,
                amount: "100 000 000 000 000 000 000 000 000 000 000.00 SOL",
                amountFiat: "999 999 999 999 999 999 999 999 999 999 999 999 999.98$",
                tokenIconInfo: .init(
                    name: "optimism",
                    blockchainIconName: nil,
                    imageURL: TokenIconURLBuilder().iconURL(id: "solana"),
                    isCustom: false,
                    customTokenColor: nil
                )
            ),
        ]) {
            AmountSummaryView(data: $0)
        }
        .interSectionPadding(12)
        .verticalPadding(0)
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}
