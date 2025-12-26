//
//  AccountsAwareAddTokenView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemAccounts
import TangemLocalization

struct AccountsAwareAddTokenView: View {
    @ObservedObject var viewModel: AccountsAwareAddTokenViewModel

    private var buttonIcon: MainButton.Icon? {
        viewModel.needsCardDerivation ? .trailing(Assets.tangemIcon) : nil
    }

    var body: some View {
        VStack(spacing: 0) {
            EntitySummaryView(viewState: viewModel.tokenItemViewState, kingfisherImageCache: .default)
                .defaultRoundedBackground(with: Colors.Background.action)
                .padding(.bottom, 14)

            VStack(spacing: .zero) {
                accountWalletSelector

                Separator(height: .minimal, color: Colors.Stroke.primary)

                networkSelector
            }
            .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 0)
            .padding(.bottom, 24)

            MainButton(
                title: Localization.commonAddToken,
                icon: buttonIcon,
                isLoading: viewModel.isSaving,
                isDisabled: viewModel.isSaving,
                action: { viewModel.handleViewEvent(.addTokenButtonTapped) }
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .padding(.top, 12)
        .animation(.default, value: viewModel.isSaving)
    }

    // MARK: - Account/Wallet Selector

    private var accountWalletSelector: some View {
        BaseOneLineRowButton(
            icon: nil,
            title: viewModel.accountWalletSelectorState.label,
            shouldShowTrailingIcon: viewModel.accountWalletSelectorState.isSelectionAvailable,
            action: { viewModel.handleViewEvent(.accountWalletSelectorTapped) },
            trailingView: { accountWalletTrailingView }
        )
        .verticalPadding(12)
        .allowsHitTesting(viewModel.accountWalletSelectorState.isSelectionAvailable)
    }

    @ViewBuilder
    private var accountWalletTrailingView: some View {
        switch viewModel.accountWalletSelectorState.trailingContent {
        case .walletName(let name):
            Text(name)
                .style(Fonts.Regular.body, color: Colors.Text.tertiary)

        case .account(let iconData, let name):
            HStack(spacing: 4) {
                AccountIconView(data: iconData)
                    .settings(.smallSized)

                Text(name)
                    .style(Fonts.Regular.body, color: Colors.Text.tertiary)
            }
        }
    }

    // MARK: - Network Selector

    private var networkSelector: some View {
        BaseOneLineRowButton(
            icon: nil,
            title: viewModel.networkSelectorState.label,
            shouldShowTrailingIcon: viewModel.networkSelectorState.isSelectionAvailable,
            action: { viewModel.handleViewEvent(.networkSelectorTapped) },
            trailingView: { networkTrailingView }
        )
        .verticalPadding(12)
        .allowsHitTesting(viewModel.networkSelectorState.isSelectionAvailable)
    }

    private var networkTrailingView: some View {
        HStack(spacing: 4) {
            NetworkIcon(
                imageAsset: viewModel.networkSelectorState.trailingContent.imageAsset,
                isActive: true,
                isMainIndicatorVisible: false,
                showBackground: false,
                size: .init(bothDimensions: 20)
            )

            Text(viewModel.networkSelectorState.trailingContent.name)
                .style(Fonts.Regular.body, color: Colors.Text.tertiary)
        }
    }
}
