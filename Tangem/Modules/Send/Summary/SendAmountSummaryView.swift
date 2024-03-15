//
//  SendAmountSummaryView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendAmountSummaryView: View {
    let data: SendAmountSummaryViewData

    private var namespace: Namespace.ID?
    private var titleNamespaceId: String?
    private var iconNamespaceId: String?
    private var amountCryptoNamespaceId: String?
    private var amountFiatNamespaceId: String?

    private let iconSize = CGSize(bothDimensions: 36)

    init(data: SendAmountSummaryViewData) {
        self.data = data
    }

    var body: some View {
        VStack(spacing: 12) {
            TokenIcon(tokenIconInfo: data.tokenIconInfo, size: iconSize)
                .matchedGeometryEffectOptional(id: iconNamespaceId, in: namespace)
                .padding(.top, 18)
                .padding(.bottom, 6)

            VStack(spacing: 6) {
                Text(data.amount)
                    .style(Fonts.Regular.title1, color: Colors.Text.primary1)
                    .matchedGeometryEffectOptional(id: amountCryptoNamespaceId, in: namespace)

                Text(data.amountFiat)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .matchedGeometryEffectOptional(id: amountFiatNamespaceId, in: namespace)
                    .padding(.bottom, 16)
            }
            .truncationMode(.middle)
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

extension SendAmountSummaryView: Setupable {
    func setNamespace(_ namespace: Namespace.ID) -> Self {
        map { $0.namespace = namespace }
    }

    func setTitleNamespaceId(_ titleNamespaceId: String?) -> Self {
        map { $0.titleNamespaceId = titleNamespaceId }
    }

    func setIconNamespaceId(_ iconNamespaceId: String?) -> Self {
        map { $0.iconNamespaceId = iconNamespaceId }
    }

    func setAmountCryptoNamespaceId(_ amountCryptoNamespaceId: String?) -> Self {
        map { $0.amountCryptoNamespaceId = amountCryptoNamespaceId }
    }

    func setAmountFiatNamespaceId(_ amountFiatNamespaceId: String?) -> Self {
        map { $0.amountFiatNamespaceId = amountFiatNamespaceId }
    }
}

#Preview {
    GroupedScrollView(spacing: 14) {
        GroupedSection(
            [
                SendAmountSummaryViewData(
                    title: Localization.sendAmountLabel,
                    amount: "100.00 USDT",
                    amountFiat: "99.98$",
                    tokenIconInfo: .init(
                        name: "tether",
                        blockchainIconName: "ethereum.fill",
                        imageURL: IconURLBuilder().tokenIconURL(id: "tether"),
                        isCustom: false,
                        customTokenColor: nil
                    )
                ),
            ]
        ) {
            SendAmountSummaryView(data: $0)
        }
        .innerContentPadding(12)

        GroupedSection([
            SendAmountSummaryViewData(
                title: Localization.sendAmountLabel,
                amount: "100 000 000 000 000 000 000 000 000 000 000.00 SOL",
                amountFiat: "999 999 999 999 999 999 999 999 999 999 999 999 999.98$",
                tokenIconInfo: .init(
                    name: "optimism",
                    blockchainIconName: nil,
                    imageURL: IconURLBuilder().tokenIconURL(id: "solana"),
                    isCustom: false,
                    customTokenColor: nil
                )
            ),
        ]) {
            SendAmountSummaryView(data: $0)
        }
        .innerContentPadding(12)
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}
