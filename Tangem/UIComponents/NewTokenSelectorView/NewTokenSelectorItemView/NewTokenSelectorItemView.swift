//
//  NewTokenSelectorItemView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct NewTokenSelectorItemView: View {
    let viewModel: NewTokenSelectorItemViewModel

    var isDisabled: Bool {
        viewModel.disabledReason != nil
    }

    var body: some View {
        Button(action: {}) {
            TwoLineRowWithIcon(
                icon: {
                    TokenItemViewLeadingComponent(
                        tokenIconInfo: viewModel.tokenIconInfo,
                        hasMonochromeIcon: isDisabled
                    )
                },
                primaryLeadingView: {
                    Text(viewModel.name)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                        .lineLimit(1)
                },
                primaryTrailingView: {
                    LoadableTokenBalanceView(
                        state: viewModel.fiatBalance,
                        style: .init(font: Fonts.Regular.subheadline, textColor: Colors.Text.primary1),
                        loader: .init(size: .init(width: 40, height: 12))
                    )
                    .layoutPriority(3)
                },
                secondaryLeadingView: {
                    Text(viewModel.symbol)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                        .lineLimit(1)
                },
                secondaryTrailingView: {
                    LoadableTokenBalanceView(
                        state: viewModel.cryptoBalance,
                        style: .init(font: Fonts.Regular.caption1, textColor: Colors.Text.tertiary),
                        loader: .init(size: .init(width: 40, height: 12))
                    )
                    .layoutPriority(3)
                }
            )
            .padding(14)
        }
    }
}
