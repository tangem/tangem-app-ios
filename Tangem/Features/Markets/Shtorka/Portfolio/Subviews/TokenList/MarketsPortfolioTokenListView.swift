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

struct MarketsPortfolioTokenListView: View {
    typealias ViewModel = MarketsPortfolioTokenListViewModel

    @ObservedObject var viewModel: ViewModel

    @State private var topBarHeight: CGFloat = 0
    @State private var bottomPromoHeight: CGFloat = 0

    @ScaledMetric private var contentPadding: CGFloat = .unit(.x4)
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

    var body: some View {
        ZStack {
            wallets

            ZStack(alignment: .top) {
                LinearGradient(
                    colors: [
                        Color.Tangem.Surface.level2,
                        Color.Tangem.Surface.level2.opacity(0),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 80)
                .allowsHitTesting(false)

                topBar
                    .padding(.horizontal, topBarHorizontalPadding)
                    .padding(.vertical, topBarVerticalPadding)
                    .readGeometry(\.size.height, bindTo: $topBarHeight)
                    .frame(maxHeight: .infinity, alignment: .top)
            }

            if let promo = viewModel.addTokenPromo {
                bottomPromoView(promo: promo)
                    .readGeometry(\.size.height, bindTo: $bottomPromoHeight)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .background(Color.Tangem.Surface.level2)
        .floatingSheetConfiguration { configuration in
            configuration.sheetFrameUpdateAnimation = .contentFrameUpdate
            configuration.backgroundInteractionBehavior = .consumeTouches
            configuration.sheetBackgroundColor = Color.Tangem.Surface.level2
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
        ZStack {
            Text(viewModel.barTitle)
                .style(.Tangem.Heading17.medium, color: .Tangem.Text.Neutral.primary)

            TangemButton(
                content: .icon(Assets.DesignSystem.close),
                action: viewModel.onCloseTap
            )
            .setStyleType(.secondary)
            .setCornerStyle(.rounded)
            .setSize(.x10)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    func bottomPromoView(promo: ViewModel.AddTokenPromo) -> some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.Tangem.Surface.level2.opacity(0), Color.Tangem.Surface.level2],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: promoFadeHeight)
            .allowsHitTesting(false)

            AddToPortfolioPromoView(iconURL: promo.iconURL, action: promo.action)
                .padding(.horizontal, contentPadding)
                .padding(.bottom, contentPadding)
                .background(Color.Tangem.Surface.level2)
        }
    }
}

// MARK: - Wallet subviews

private extension MarketsPortfolioTokenListView {
    var wallets: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: walletsSpacing) {
                Color.clear.frame(height: topBarHeight)

                ForEach(viewModel.sections, id: \.id) { section in
                    wallet(section: section)
                }

                Color.clear.frame(height: bottomPromoHeight)
            }
            .padding(.horizontal, contentPadding)
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
                .style(.Tangem.Subheadline.medium, color: .Tangem.Text.Neutral.secondary)

            thumbnail.map {
                MiniatureWalletView(type: $0)
                    .frame(width: thumbnailSide, height: thumbnailSide)
            }
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
        .style(.Tangem.Caption12.regular, color: .Tangem.Text.Neutral.primary)
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

    func token(row: ViewModel.TokenRow) -> some View {
        Button(action: row.onTap) {
            MarketsPortfolioTokenListRowView(viewModel: row.model)
        }
        .buttonStyle(.plain)
    }
}
