//
//  AccountsAwareTokenSelectorItemView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct AccountsAwareTokenSelectorItemView: View {
    @ObservedObject var viewModel: AccountsAwareTokenSelectorItemViewModel

    var body: some View {
        Button(action: viewModel.action) {
            TwoLineRowWithIcon(
                icon: {
                    TokenItemViewLeadingComponent(
                        tokenIconInfo: viewModel.tokenIconInfo,
                        hasMonochromeIcon: viewModel.disabledReason != nil
                    )
                },
                primaryLeadingView: {
                    Text(viewModel.name)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                        .lineLimit(1)
                },
                primaryTrailingView: { primaryTrailingView },
                secondaryLeadingView: { secondaryLeadingView },
                secondaryTrailingView: { secondaryTrailingView }
            )
            .padding(.vertical, 14)
        }
        .disabled(viewModel.disabledReason != nil)
        .background(Colors.Background.action)
    }

    @ViewBuilder
    private var primaryTrailingView: some View {
        switch viewModel.disabledReason {
        case .none:
            LoadableBalanceView(
                state: viewModel.fiatBalance,
                style: .init(font: Fonts.Regular.subheadline, textColor: Colors.Text.primary1),
                loader: .init(size: .init(width: 40, height: 12))
            )
            .layoutPriority(3)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var secondaryTrailingView: some View {
        switch viewModel.disabledReason {
        case .none:
            LoadableBalanceView(
                state: viewModel.cryptoBalance,
                style: .init(font: Fonts.Regular.caption1, textColor: Colors.Text.tertiary),
                loader: .init(size: .init(width: 40, height: 12))
            )
            .layoutPriority(3)
        default:
            EmptyView()
        }
    }

    private var secondaryLeadingView: some View {
        Group {
            switch viewModel.disabledReason {
            case .none:
                Text(viewModel.symbol)
            case .unavailableForOnramp:
                Text(Localization.tokensListUnavailableToPurchaseHeader)
            case .unavailableForSwap:
                Text(Localization.tokensListUnavailableToSwapSourceHeader)
            case .unavailableForSell:
                Text(Localization.tokensListUnavailableToSellHeader)
            }
        }
        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
        .lineLimit(1)
    }
}
