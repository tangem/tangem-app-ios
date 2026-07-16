//
//  AddFundsTokenInfoView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccounts
import TangemAssets
import TangemUI

struct AddFundsTokenInfoView: View {
    let viewData: ViewData

    var body: some View {
        VStack(spacing: 12) {
            TokenIcon(tokenIconInfo: viewData.tokenIconInfo, size: CGSize(width: 64, height: 64))

            VStack(spacing: 4) {
                LoadableTextView(
                    state: viewData.fiatBalance,
                    font: Font.Tangem.Title44.semibold.font,
                    textColor: .Tangem.Text.Neutral.primary,
                    loaderSize: Constants.fiatLoaderSize,
                    isSensitiveText: true
                )
                .minimumScaleFactor(0.5)

                LoadableTextView(
                    state: viewData.cryptoBalance,
                    font: Font.Tangem.Subheadline.regular.font,
                    textColor: .Tangem.Text.Neutral.tertiary,
                    loaderSize: Constants.cryptoLoaderSize,
                    isSensitiveText: true
                )
            }

            badge
        }
        .infinityFrame(axis: .horizontal)
    }

    @ViewBuilder
    private var badge: some View {
        if let badge = viewData.badge {
            switch badge {
            case .account(let accountBadge):
                capsule {
                    AccountInlineHeaderView(iconData: accountBadge.iconData, name: accountBadge.name)
                }

            case .wallet(let walletBadge):
                capsule {
                    HStack(spacing: 6) {
                        Text(walletBadge.name)
                            .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        walletThumbnail(walletBadge.thumbnail)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func walletThumbnail(_ type: ThumbnailWalletViewType?) -> some View {
        if let type {
            MiniatureWalletView(type: type)
                .frame(width: Constants.walletThumbnailSize, height: Constants.walletThumbnailSize)
        }
    }

    private func capsule<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Colors.Background.action)
            )
    }
}

// MARK: - Constants

private extension AddFundsTokenInfoView {
    enum Constants {
        static let fiatLoaderSize = CGSize(width: 140, height: 44)
        static let cryptoLoaderSize = CGSize(width: 100, height: 18)
        static let walletThumbnailSize: CGFloat = 20
    }
}

// MARK: - ViewData

extension AddFundsTokenInfoView {
    struct ViewData {
        let tokenIconInfo: TokenIconInfo
        let fiatBalance: LoadableTextView.State
        let cryptoBalance: LoadableTextView.State
        let badge: Badge?
    }

    enum Badge {
        /// Account name + icon — shown when the wallet has multiple accounts.
        case account(AccountBadge)
        /// Selected wallet thumbnail + name — shown when there are multiple wallets and no accounts.
        case wallet(WalletBadge)
    }

    struct AccountBadge: Hashable {
        let iconData: AccountIconView.ViewData
        let name: String
    }

    struct WalletBadge {
        let thumbnail: ThumbnailWalletViewType?
        let name: String

        init(thumbnail: ThumbnailWalletViewType?, name: String) {
            self.thumbnail = thumbnail
            self.name = name
        }
    }
}

// MARK: - FormattedTokenBalanceType + LoadableTextView.State

extension FormattedTokenBalanceType {
    var loadableTextViewState: LoadableTextView.State {
        switch self {
        case .loading: .loading
        case .loaded(let value): .loaded(text: value)
        case .failure(let cached): .loaded(text: cached.value)
        }
    }
}
