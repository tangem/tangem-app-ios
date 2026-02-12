//
//  AccountRowButtonView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemAccounts
import TangemAccessibilityIdentifiers

struct AccountRowButtonView<Trailing: View>: View {
    @ObservedObject var viewModel: AccountRowButtonViewModel

    @ScaledMetric private var balanceLoaderHeight: CGFloat = 12
    @ScaledMetric private var balanceLoaderWidth: CGFloat = 40

    let trailing: Trailing

    init(
        viewModel: AccountRowButtonViewModel,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.viewModel = viewModel
        self.trailing = trailing()
    }

    var body: some View {
        Button(action: viewModel.onSelect) {
            AccountIconWithContentView(
                iconData: viewModel.iconData,
                name: viewModel.name,
                subtitle: { subtitleView },
                trailing: { trailing }
            )
        }
        .disabled(viewModel.isDisabled)
        .accessibilityIdentifier(AccountsAccessibilityIdentifiers.walletSettingsAccountRow(accountName: viewModel.name))
    }

    @ViewBuilder
    private var subtitleView: some View {
        switch viewModel.subtitleState {
        case .descriptionOnly(let description):
            Text(description)

        case .descriptionWithBalance(let description, let balanceState):
            HStack(spacing: 4) {
                Text(description)

                Text(AppConstants.dotSign)

                makeLoadableBalanceView(state: balanceState)
            }

        case .balanceOnly(let balanceState):
            makeLoadableBalanceView(state: balanceState)

        case .unavailableWithReason(let reason):
            Text(reason)

        case .none:
            EmptyView()
        }
    }

    private func makeLoadableBalanceView(state: LoadableBalanceView.State) -> some View {
        LoadableBalanceView(
            state: state,
            style: .init(font: Fonts.Regular.caption1, textColor: Colors.Text.tertiary),
            loader: .init(size: CGSize(width: balanceLoaderWidth, height: balanceLoaderHeight))
        )
    }
}

// MARK: - Default Empty Trailing

extension AccountRowButtonView where Trailing == EmptyView {
    init(viewModel: AccountRowButtonViewModel) {
        self.viewModel = viewModel
        trailing = EmptyView()
    }
}
