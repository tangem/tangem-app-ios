//
//  BalancesView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct BalancesView<ViewModel: BalancesViewModel>: View {
    @ObservedObject var viewModel: ViewModel

    let yieldBalanceInfoAction: (() -> Void)?

    init(viewModel: ViewModel, yieldBalanceInfoAction: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.yieldBalanceInfoAction = yieldBalanceInfoAction
    }

    var body: some View {
        fiatBalance

        cryptoBalance
            .monospacedDigit()
    }

    var fiatBalance: some View {
        LoadableTokenBalanceView(
            state: viewModel.fiatBalance,
            style: .init(font: Fonts.Regular.title1, textColor: Colors.Text.primary1),
            loader: .init(
                size: .init(width: 102, height: 24),
                padding: .init(top: 5, leading: 0, bottom: 5, trailing: 0),
                cornerRadius: 6
            ),
        )
        .setContentTransition(viewModel.isRefreshing ? nil : .numeric(isCountdown: false))
        .accessibilityIdentifier(viewModel.balanceAccessibilityIdentifier)
    }

    @ViewBuilder
    var cryptoBalance: some View {
        if viewModel.isYieldActive {
            cryptoBalanceContent
                .yieldIdentificationIfNeeded {
                    yieldBalanceInfoAction?()
                }
        } else {
            cryptoBalanceContent
        }
    }

    var cryptoBalanceContent: LoadableTokenBalanceView {
        LoadableTokenBalanceView(
            state: viewModel.cryptoBalance,
            style: .init(font: Fonts.Regular.footnote, textColor: Colors.Text.tertiary),
            loader: .init(
                size: .init(width: 70, height: 12),
                padding: .init(top: 2, leading: 0, bottom: 2, trailing: 0)
            ),
        )
        .setContentTransition(viewModel.isRefreshing ? nil : .numeric(isCountdown: false))
    }
}
