//
//  MarketsPortfolioTokenListView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAccounts
import TangemAssets
import TangemLocalization
import TangemAccessibilityIdentifiers

struct MarketsPortfolioTokenListView: View {
    typealias ViewModel = MarketsPortfolioTokenListViewModel

    @ObservedObject var viewModel: ViewModel

    @ScaledMetric private var walletsHorizontalPadding: CGFloat = .unit(.x4)
    @ScaledMetric private var topBarVerticalPadding: CGFloat = .unit(.x4)
    @ScaledMetric private var topBarHorizontalPadding: CGFloat = .unit(.x3)
    @ScaledMetric private var walletsSpacing: CGFloat = .unit(.x6)
    @ScaledMetric private var walletSpacing: CGFloat = .unit(.x4)
    @ScaledMetric private var walletHeaderSpacing: CGFloat = .unit(.x1)
    @ScaledMetric private var walletHeaderLeadingPadding: CGFloat = .unit(.x4)
    @ScaledMetric private var accountsSpacing: CGFloat = .unit(.x2)
    @ScaledMetric private var accountPadding: CGFloat = .unit(.x3)
    @ScaledMetric private var accountSpacing: CGFloat = .unit(.x5)
    @ScaledMetric private var accountCornerRadius: CGFloat = .unit(.x5)
    @ScaledMetric private var accountHeaderLeadingPadding: CGFloat = .unit(.x1)
    @ScaledMetric private var tokenRowsSpacing: CGFloat = .unit(.x6)
    @ScaledMetric private var promoFadeHeight: CGFloat = 60
    @ScaledMetric private var thumbnailSide = CGFloat.unit(.x5)

    private let backgroundColor: Color = .Tangem.Surface.level2

    var body: some View {
        wallets
            .safeAreaInset(edge: .top, spacing: 0) { topBar }
            .safeAreaInset(edge: .bottom, spacing: 20) { bottomBar }
            .background(backgroundColor)
            .overlay(alignment: .bottom) { walletsBlur }
            .floatingSheetConfiguration { configuration in
                configuration.sheetFrameUpdateAnimation = .contentFrameUpdate
                configuration.backgroundInteractionBehavior = .consumeTouches
                configuration.sheetBackgroundColor = backgroundColor
            }
    }
}

// MARK: - Animations

private extension Animation {
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.5)
}

// MARK: - Subviews

private extension MarketsPortfolioTokenListView {
    var topBar: some View {
        navigationBar
            .padding(.horizontal, topBarHorizontalPadding)
            .padding(.vertical, topBarVerticalPadding)
            .background {
                navigationBarBlur
            }
    }

    var navigationBar: some View {
        ZStack {
            Text(viewModel.barTitle)
                .style(Font.Tangem.Heading17.semibold, color: .Tangem.Text.Neutral.primary)

            TangemButton(
                content: .icon(Assets.DesignSystem.close),
                action: viewModel.onCloseTap
            )
            .setStyleType(.secondary)
            .setSize(.x10)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    var navigationBarBlur: some View {
        LinearGradient(
            colors: [
                backgroundColor,
                backgroundColor.opacity(0),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
    }

    @ViewBuilder
    var bottomBar: some View {
        if let promo = viewModel.addTokenPromo {
            addTokenView(action: promo.action)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .background(backgroundColor)
        }
    }

    func addTokenView(action: @escaping () -> Void) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Localization.commonAddToken)
                    .style(.Tangem.Body16.medium.font, color: .Tangem.Text.Neutral.primary)

                Text(Localization.marketsTokenAddSubtitle)
                    .style(.Tangem.Caption12.regular.font, color: .Tangem.Text.Neutral.secondary)
            }

            Spacer(minLength: 8)

            TangemButton(
                content: .text(AttributedString(Localization.marketsAddToken)),
                action: action
            )
            .setSize(.x9)
            .setStyleType(.secondary)
            .accessibilityIdentifier(MainAccessibilityIdentifiers.addToPortfolioButton)
        }
    }
}

// MARK: - Wallet subviews

private extension MarketsPortfolioTokenListView {
    var wallets: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: walletsSpacing) {
                ForEach(viewModel.sections, id: \.id) { section in
                    wallet(section: section)
                }
            }
            .padding(.horizontal, walletsHorizontalPadding)
            .background(backgroundColor)
        }
    }

    func wallet(section: ViewModel.WalletSection) -> some View {
        VStack(alignment: .leading, spacing: walletSpacing) {
            if viewModel.hasWalletHeader {
                walletHeader(title: section.title, thumbnail: section.thumbnail)
                    .padding(.leading, walletHeaderLeadingPadding)
            }

            accounts(section.accounts)
        }
    }

    func walletHeader(title: String, thumbnail: ThumbnailWalletViewType?) -> some View {
        HStack(spacing: walletHeaderSpacing) {
            Text(title)
                .style(Font.Tangem.Subheadline.medium, color: .Tangem.Text.Neutral.secondary)

            thumbnail.map {
                MiniatureWalletView(type: $0)
                    .frame(width: thumbnailSide, height: thumbnailSide)
            }
        }
    }

    @ViewBuilder
    var walletsBlur: some View {
        if viewModel.addTokenPromo == nil {
            LinearGradient(
                colors: [
                    backgroundColor.opacity(0),
                    backgroundColor,
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: promoFadeHeight)
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Account subviews

private extension MarketsPortfolioTokenListView {
    func accounts(_ items: [ViewModel.AccountSection]) -> some View {
        VStack(spacing: accountsSpacing) {
            ForEach(items, id: \.id) { item in
                account(section: item)
            }
        }
    }

    func account(section: ViewModel.AccountSection) -> some View {
        VStack(alignment: .leading, spacing: accountSpacing) {
            if viewModel.hasAccountHeader {
                accountHeader(title: section.title, icon: section.icon)
                    .padding(.leading, accountHeaderLeadingPadding)
            }

            tokenRows(section.tokenRows)
        }
        .padding(accountPadding)
        .background(Color.Tangem.Surface.level3, in: RoundedRectangle(cornerRadius: accountCornerRadius))
    }

    func accountHeader(title: String, icon: AccountModel.Icon) -> some View {
        let iconData = AccountModelUtils.UI.iconViewData(
            icon: icon,
            accountName: title
        )

        return AccountIconWithContentView(
            iconData: iconData,
            name: title
        )
        .iconSettings(.smallSized)
        .style(Font.Tangem.Caption12.regular, color: .Tangem.Text.Neutral.primary)
    }
}

// MARK: - Token rows subviews

private extension MarketsPortfolioTokenListView {
    func tokenRows(_ items: [ViewModel.TokenRow]) -> some View {
        VStack(spacing: tokenRowsSpacing) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                token(row: item)
            }
        }
    }

    @ViewBuilder
    func token(row: ViewModel.TokenRow) -> some View {
        if let onTap = row.onTap {
            Button(action: onTap) {
                MarketsPortfolioTokenListRowView(viewModel: row.model)
            }
            .buttonStyle(.plain)
        } else {
            MarketsPortfolioTokenListRowView(viewModel: row.model)
        }
    }
}
