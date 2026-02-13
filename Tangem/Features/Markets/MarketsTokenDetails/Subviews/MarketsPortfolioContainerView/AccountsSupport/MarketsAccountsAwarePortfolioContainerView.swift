//
//  MarketsAccountsAwarePortfolioContainerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemAccessibilityIdentifiers
import TangemAccounts

/// Copy-pasted MarketsPortfolioContainerView and added accounts support
struct MarketsAccountsAwarePortfolioContainerView: View {
    typealias ListStyle = MarketsAccountsAwarePortfolioContainerViewModel.TypeView.ListStyle
    typealias UserWalletWithTokensData = MarketsAccountsAwarePortfolioContainerViewModel.TypeView.UserWalletWithTokensData
    typealias UserWalletWithAccountsData = MarketsAccountsAwarePortfolioContainerViewModel.TypeView.UserWalletWithAccountsData
    typealias AccountWithTokenItemsData = MarketsAccountsAwarePortfolioContainerViewModel.TypeView.AccountWithTokenItemsData
    typealias AccountData = MarketsAccountsAwarePortfolioContainerViewModel.TypeView.AccountData

    @ObservedObject var viewModel: MarketsAccountsAwarePortfolioContainerViewModel

    // MARK: - Body

    var body: some View {
        contentView
            .if(!viewModel.typeView.isList) { $0.padding(.bottom, 12) }
    }

    // MARK: - Content

    private var contentView: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerView
            contentBodyView
        }
    }

    @ViewBuilder
    private var contentBodyView: some View {
        switch viewModel.typeView {
        case .empty:
            emptyView
                .transition(.opacity.combined(with: .identity))

        case .loading:
            loadingView

        case .list(let listStyle):
            listView(for: listStyle)

        case .unavailable:
            unavailableView
                .transition(.opacity.combined(with: .identity))

        case .unsupported:
            unsupportedView
                .transition(.opacity.combined(with: .identity))
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text(Localization.marketsCommonMyPortfolio)
                .style(Fonts.Bold.title3, color: Colors.Text.primary1)

            Spacer()

            if viewModel.typeView.isList {
                CapsuleButton(icon: .trailing(Assets.plus14), title: Localization.marketsAddToken, action: viewModel.onAddTapAction)
                    .disabled(viewModel.isAddTokenButtonDisabled)
                    .loading(viewModel.isLoadingNetworks)
            }
        }
        .padding(.horizontal, Constants.blockHeaderHorizontalPadding)
    }

    // MARK: - List Views

    @ViewBuilder
    private func listView(for listStyle: ListStyle) -> some View {
        switch listStyle {
        case .justWallets(let walletsData):
            justWalletsView(walletsData: walletsData)
        case .walletsWithAccounts(let walletsData):
            walletsWithAccountsView(walletsData: walletsData)
        }
    }

    private func justWalletsView(walletsData: [UserWalletWithTokensData]) -> some View {
        // Right now we need to use here VStack instead of LazyVStack because of not resolved issues
        // with expanding and collapsing animations for quick actions. Will be investigated in [REDACTED_INFO]
        VStack(spacing: 8) {
            ForEach(walletsData, id: \.userWalletId) { walletData in
                VStack(spacing: Constants.headerContentVerticalSpacing) {
                    inlineWalletHeader(walletName: walletData.userWalletName)
                        .padding(.top, 14)

                    tokenItemsList(walletData.tokenItems)
                }
                .roundedBackground(with: Colors.Background.action, verticalPadding: 0, horizontalPadding: Constants.cardPadding)
            }
        }
    }

    private func walletsWithAccountsView(walletsData: [UserWalletWithAccountsData]) -> some View {
        // Right now we need to use here VStack instead of LazyVStack because of not resolved issues
        // with expanding and collapsing animations for quick actions. Will be investigated in [REDACTED_INFO]
        VStack(spacing: 16) {
            ForEach(walletsData, id: \.userWalletId) { walletData in
                VStack(alignment: .leading, spacing: Constants.headerContentVerticalSpacing) {
                    prominentWalletHeader(walletName: walletData.userWalletName)
                        .padding(.top, 14)

                    ForEach(walletData.accountsWithTokenItems, id: \.accountData.id) { accountWithTokens in
                        accountCard(accountWithTokens)
                    }
                }
            }
        }
    }

    // MARK: - Account Card

    private func accountCard(_ accountWithTokens: AccountWithTokenItemsData) -> some View {
        VStack(spacing: .zero) {
            accountHeader(accountData: accountWithTokens.accountData)
                .padding(.top, 14)
                .padding(.bottom, 8)

            tokenItemsList(accountWithTokens.tokenItems)
        }
        .roundedBackground(with: Colors.Background.action, verticalPadding: 0, horizontalPadding: Constants.cardPadding)
    }

    // MARK: - Token Items List

    private func tokenItemsList(_ tokenItems: [MarketsPortfolioTokenItemViewModel]) -> some View {
        ForEach(indexed: tokenItems.indexed()) { _, itemViewModel in
            MarketsPortfolioTokenItemView(
                viewModel: itemViewModel,
                isExpanded: viewModel.tokenWithExpandedQuickActions === itemViewModel
            )
        }
    }

    // MARK: - Section Headers

    private func prominentWalletHeader(walletName: String) -> some View {
        Text(walletName)
            .style(Fonts.Bold.headline, color: Colors.Text.primary1)
            .padding(.horizontal, Constants.blockHeaderHorizontalPadding)
    }

    private func inlineWalletHeader(walletName: String) -> some View {
        HStack {
            Text(walletName)
                .style(Fonts.Bold.caption1, color: Colors.Text.primary1)
            Spacer()
        }
    }

    private func accountHeader(accountData: AccountData) -> some View {
        AccountInlineHeaderView(iconData: accountData.iconInfo, name: accountData.name)
            .expandsHorizontally(true)
    }

    // MARK: - Empty States

    private var emptyView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.marketsAddToMyPortfolioDescription)
                .lineLimit(2)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

            MainButton(title: Localization.commonAddToPortfolio) {
                viewModel.onAddTapAction()
            }
            .accessibilityIdentifier(MainAccessibilityIdentifiers.addToPortfolioButton)
        }
        .defaultRoundedBackground(with: Colors.Background.action)
    }

    private var unavailableView: some View {
        Text(Localization.marketsAddToMyPortfolioUnavailableForWalletDescription)
            .style(.footnote, color: Colors.Text.tertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var unsupportedView: some View {
        Text(Localization.marketsAddToMyPortfolioUnavailableDescription)
            .style(.footnote, color: Colors.Text.tertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Loading State

    private var loadingView: some View {
        VStack(alignment: .leading, spacing: 6) {
            skeletonView(width: .infinity, height: Constants.skeletonHeight)
            skeletonView(width: 218, height: Constants.skeletonHeight)
        }
    }

    private func skeletonView(width: CGFloat, height: CGFloat) -> some View {
        SkeletonView()
            .cornerRadiusContinuous(3)
            .frame(maxWidth: width, minHeight: height, maxHeight: height)
    }
}

// MARK: - Constants

private extension MarketsAccountsAwarePortfolioContainerView {
    enum Constants {
        static let cardPadding: CGFloat = 14
        static let skeletonHeight: CGFloat = 15
        static let headerContentVerticalSpacing: CGFloat = 8
        static let blockHeaderHorizontalPadding: CGFloat = 8
    }
}
