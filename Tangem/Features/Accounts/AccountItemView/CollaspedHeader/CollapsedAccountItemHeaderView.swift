//
//  CollapsedAccountItemHeaderView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemAccounts

struct CollapsedAccountItemHeaderView: View {
    let name: String
    let iconData: AccountIconView.ViewData
    let tokensCount: String
    let totalFiatBalance: LoadableTokenBalanceView.State
    let priceChange: TokenPriceChangeView.State

    var body: some View {
        TwoLineRowWithIcon(
            icon: {
                AccountIconView(data: iconData)
            },
            primaryLeadingView: {
                Text(name)
                    .style(
                        Fonts.Bold.subheadline,
                        color: Colors.Text.primary1
                    )
            },
            primaryTrailingView: {
                LoadableTokenBalanceView(
                    state: totalFiatBalance,
                    style: .init(font: Fonts.Regular.subheadline, textColor: Colors.Text.primary1),
                    loader: .init(size: .init(width: 40, height: 12))
                )
            },
            secondaryLeadingView: {
                Text(tokensCount)
                    .style(
                        Fonts.Bold.caption1,
                        color: Colors.Text.tertiary
                    )
            },
            secondaryTrailingView: {
                TokenPriceChangeView(
                    state: priceChange,
                    showSkeletonWhenLoading: true,
                    showSeparatorForNeutralStyle: false
                )
            }
        )
        .padding(14.0)
    }
}

#if DEBUG
#Preview {
    ZStack {
        Color.gray

        CollapsedAccountItemHeaderView(
            name: "Test",
            iconData: .init(backgroundColor: .red, nameMode: .letter("A")),
            tokensCount: "5 Tokens",
            totalFiatBalance: .loaded(text: "$1234.56"),
            priceChange: .loaded(signType: .positive, text: "+5.67%")
        )
    }
}
#endif
