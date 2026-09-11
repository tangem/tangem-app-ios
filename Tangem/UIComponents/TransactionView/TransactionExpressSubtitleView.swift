//
//  TransactionExpressSubtitleView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccounts
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

/// Renders the redesigned Express (swap / onramp) subtitle line: direction prefix (`to:` / `from:`) +
/// counterparty currency (icon + symbol) + an optional " in [account/wallet]" segment.
struct TransactionExpressSubtitleView: View {
    let model: TransactionDisplayModel.ExpressSubtitle

    @ScaledMetric private var glyphSize: CGFloat = 16

    var body: some View {
        HStack(spacing: .unit(.x1)) {
            Text(model.direction.localizedPrefix)
                .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.tertiary)

            leadingIcon

            Text(model.symbol)
                .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.primary)
                .lineLimit(1)

            if let owner = model.owner {
                ownerSegment(owner)
            }
        }
        .lineLimit(1)
    }

    @ViewBuilder
    private var leadingIcon: some View {
        switch model.leading {
        case .token(let tokenIconInfo):
            TokenIcon(tokenIconInfo: tokenIconInfo, size: CGSize(bothDimensions: glyphSize), isWithOverlays: false)
        case .fiat(let url):
            IconView(url: url, size: CGSize(bothDimensions: glyphSize))
        }
    }

    @ViewBuilder
    private func ownerSegment(_ owner: TransactionViewModel.SubtitleOwner) -> some View {
        switch owner {
        case .accountInCurrentWallet(let name, let icon),
             .accountInOtherWallet(let name, let icon):
            HStack(spacing: .unit(.x1)) {
                inPrefix
                AccountIconView(data: icon).settings(.smallSized)
                ownerName(name)
            }

        case .wallet(let name, _, _):
            HStack(spacing: .unit(.x1)) {
                inPrefix
                ownerName(name)
            }

        case .unresolved:
            EmptyView()
        }
    }

    private var inPrefix: some View {
        Text(Localization.commonIn)
            .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.tertiary)
    }

    private func ownerName(_ name: String) -> some View {
        Text(name)
            .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.primary)
            .lineLimit(1)
    }
}
