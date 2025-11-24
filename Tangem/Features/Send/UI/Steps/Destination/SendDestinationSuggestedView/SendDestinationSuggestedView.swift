//
//  SendDestinationSuggestedView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAccounts
import TangemAssets
import TangemLocalization
import TangemAccessibilityIdentifiers

struct SendDestinationSuggestedView: View {
    let viewModel: SendDestinationSuggestedViewModel

    private let cellVerticalSpacing: Double = 4
    private let cellHorizontalSpacing: Double = 12

    var body: some View {
        userWalletsSection

        recentTransactionSection
    }

    var userWalletsSection: some View {
        GroupedSection(viewModel.suggestedWallets) { wallet in
            let index = viewModel.suggestedWallets.firstIndex(where: { $0.id == wallet.id }) ?? 0
            SendDestinationSuggestedWalletView(
                address: wallet.wallet.address,
                iconViewModel: wallet.addressIconViewModel,
                addressAccessibilityIdentifier: SendAccessibilityIdentifiers.suggestedDestinationWalletCell(index: index),
                action: wallet.action
            ) {
                HStack(spacing: 4) {
                    Text(wallet.wallet.name)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                        .lineLimit(1)

                    if let account = wallet.wallet.account {
                        Text(AppConstants.dotSign)
                            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                        AccountIconView(data: account.icon)
                            .settings(.extraSmallSized)

                        Text(account.name)
                            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    }
                }
            }
        } header: {
            DefaultHeaderView(viewModel.suggestedWalletsHeader)
                .accessibilityIdentifier(SendAccessibilityIdentifiers.suggestedDestinationHeader)
                .padding(.top, 12)
        }
        .backgroundColor(Colors.Background.action)
        .interItemSpacing(0)
        .separatorStyle(.none)
        .accessibilityIdentifier(SendAccessibilityIdentifiers.suggestedDestinationMyWalletsBlock)
    }

    var recentTransactionSection: some View {
        GroupedSection(viewModel.suggestedRecentTransaction) { transaction in
            let index = viewModel.suggestedRecentTransaction.firstIndex(where: { $0.id == transaction.id }) ?? 0
            SendDestinationSuggestedWalletView(
                address: transaction.record.address,
                iconViewModel: transaction.addressIconViewModel,
                addressAccessibilityIdentifier: SendAccessibilityIdentifiers.suggestedDestinationTransactionCell(index: index),
                action: transaction.action
            ) {
                HStack(spacing: 6) {
                    directionArrow(isOutgoing: transaction.record.isOutgoing)
                        .frame(size: CGSize(bothDimensions: 16))
                        .background(Colors.Background.tertiary)
                        .clipShape(Circle())

                    SensitiveText(builder: transaction.record.description, sensitive: transaction.record.amountFormatted)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                        .truncationMode(.middle)
                        .lineLimit(1)
                }
            }
        } header: {
            DefaultHeaderView(Localization.sendRecentTransactions)
                .accessibilityIdentifier(SendAccessibilityIdentifiers.suggestedDestinationHeader)
                .padding(.top, 12)
        }
        .backgroundColor(Colors.Background.action)
        .interItemSpacing(0)
        .separatorStyle(.none)
    }

    @ViewBuilder
    private func directionArrow(isOutgoing: Bool) -> some View {
        if isOutgoing {
            Assets.Send.arrowUp.image
        } else {
            Assets.Send.arrowDown.image
        }
    }
}

// MARK: - Row view

struct SendDestinationSuggestedWalletView<BottomView: View>: View {
    let address: String
    let iconViewModel: AddressIconViewModel
    let addressAccessibilityIdentifier: String
    let action: () -> Void
    let bottomView: () -> BottomView

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                AddressIconView(viewModel: iconViewModel)
                    .frame(size: CGSize(bothDimensions: 36))

                VStack(alignment: .leading, spacing: 4) {
                    Text(address)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
                        .truncationMode(.middle)
                        .lineLimit(1)
                        .infinityFrame(axis: .horizontal, alignment: .leading)
                        .accessibilityIdentifier(addressAccessibilityIdentifier)

                    bottomView()
                }
            }
            .padding(.vertical, 16)
        }
    }
}
