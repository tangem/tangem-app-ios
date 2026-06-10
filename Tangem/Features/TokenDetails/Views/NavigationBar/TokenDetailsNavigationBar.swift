//
//  TokenDetailsNavigationBar.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccounts
import TangemAssets
import TangemUI
import TangemAccessibilityIdentifiers

struct TokenDetailsNavigationBar: View {
    let viewModel: TokenDetailsNavigationBarViewModel

    @ScaledMetric private var walletThumbnailScaledSide = CGFloat.unit(.x5)

    var body: some View {
        VStack(spacing: .unit(.x1)) {
            title
            subtitle
        }
    }

    private var title: some View {
        HStack(spacing: .unit(.x1)) {
            Text(viewModel.title.tokenName)
                .layoutPriority(1)
                .accessibilityIdentifier(TokenAccessibilityIdentifiers.tokenNameLabel)

            storage
        }
        .foregroundStyle(Color.Tangem.Text.Neutral.primary)
        .font(.Tangem.Body16.semibold)
    }

    @ViewBuilder
    private var storage: some View {
        switch viewModel.title.storedIn {
        case .account(let icon, let accountName):
            accountStorage(icon, accountName)

        case .wallet(let walletName, let thumbnail):
            walletStorage(walletName, thumbnail)

        case .singleWallet:
            EmptyView()
        }
    }

    private func accountStorage(_ icon: AccountIconView.ViewData, _ accountName: String) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: .unit(.x1)) {
                preposition

                AccountIconView(data: icon, settings: .smallSized)
                Text(accountName)
            }

            HStack(spacing: .unit(.x1)) {
                preposition
                AccountIconView(data: icon, settings: .smallSized)
            }

            AccountIconView(data: icon, settings: .smallSized)
        }
    }

    private func walletStorage(_ walletName: String, _ thumbnail: ThumbnailWalletViewType?) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: .unit(.x1)) {
                preposition

                Text(walletName)

                if let thumbnail {
                    MiniatureWalletView(type: thumbnail)
                        .frame(width: walletThumbnailScaledSide, height: walletThumbnailScaledSide)
                }
            }

            HStack(spacing: .unit(.x1)) {
                preposition

                if let thumbnail {
                    MiniatureWalletView(type: thumbnail)
                        .frame(width: walletThumbnailScaledSide, height: walletThumbnailScaledSide)
                } else {
                    Text(walletName)
                }
            }

            if let thumbnail {
                MiniatureWalletView(type: thumbnail)
                    .frame(width: walletThumbnailScaledSide, height: walletThumbnailScaledSide)
            } else {
                Text(walletName)
            }
        }
    }

    @ViewBuilder
    private var preposition: some View {
        if let preposition = viewModel.title.storedIn.preposition {
            Text(preposition)
                .foregroundStyle(Color.Tangem.Text.Neutral.tertiary)
        }
    }

    private var subtitle: some View {
        Text(viewModel.subtitle)
            .style(.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.tertiary)
    }
}
