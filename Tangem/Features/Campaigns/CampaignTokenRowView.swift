//
//  CampaignTokenRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemUIUtils

struct CampaignTokenRowView: View {
    @ObservedObject var viewModel: TokenSelectorItemViewModel
    let networkName: String

    var body: some View {
        TwoLineRowWithIcon(
            icon: {
                TokenItemViewLeadingComponent(tokenIconInfo: viewModel.tokenIconInfo, hasMonochromeIcon: false)
            },
            primaryLeadingView: {
                Text(viewModel.name)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                    .lineLimit(1)
            },
            primaryTrailingView: {
                LoadableBalanceView(
                    state: viewModel.fiatBalance,
                    style: .init(font: Fonts.Regular.subheadline, textColor: Colors.Text.primary1),
                    loader: .init(size: .init(width: 40, height: 12))
                )
            },
            secondaryLeadingView: {
                Text(networkName)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                    .lineLimit(1)
            },
            secondaryTrailingView: {
                LoadableBalanceView(
                    state: viewModel.cryptoBalance,
                    style: .init(font: Fonts.Regular.caption1, textColor: Colors.Text.tertiary),
                    loader: .init(size: .init(width: 40, height: 12))
                )
            }
        )
    }
}
