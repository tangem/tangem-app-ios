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
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct TokenDetailsNavigationBar: View {
    let viewModel: TokenDetailsNavigationBarViewModel

    @ScaledMetric private var walletThumbnailScaledSide: CGFloat = 20

    var body: some View {
        VStack(spacing: 4) {
            title
            subtitle
        }
    }

    private var title: some View {
        HStack(spacing: 4) {
            Text(viewModel.title.tokenName)
                .layoutPriority(1)
                .accessibilityIdentifier(TokenAccessibilityIdentifiers.tokenNameLabel)

            storage
        }
        .foregroundStyle(DesignSystem.Color.textPrimary)
        .font(token: DesignSystem.Font.bodyMediumToken)
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
            HStack(spacing: 4) {
                preposition

                AccountIconView(data: icon, settings: .smallSized)
                Text(accountName)
            }

            HStack(spacing: 4) {
                preposition
                AccountIconView(data: icon, settings: .smallSized)
            }

            AccountIconView(data: icon, settings: .smallSized)
        }
    }

    private func walletStorage(_ walletName: String, _ thumbnail: ThumbnailWalletViewType?) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 4) {
                preposition

                Text(walletName)

                if let thumbnail {
                    MiniatureWalletView(type: thumbnail)
                        .frame(width: walletThumbnailScaledSide, height: walletThumbnailScaledSide)
                }
            }

            HStack(spacing: 4) {
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
                .foregroundStyle(DesignSystem.Color.textSecondary)
        }
    }

    private var subtitle: some View {
        Text(viewModel.subtitle)
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
    }
}
