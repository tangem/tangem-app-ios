//
//  WithdrawHubContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct WithdrawHubContentView: View {
    let isWithinPortfolioLoading: Bool
    let recentTokens: WithdrawHubSectionState<WithdrawHubRecentTokenItem>
    let recentAccounts: WithdrawHubSectionState<WithdrawHubRecentAccountItem>
    let onAction: (WithdrawHubViewModel.ViewAction) -> Void

    var body: some View {
        VStack(spacing: 24) {
            swapSection

            accountsSection

            Spacer()
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Subviews

private extension WithdrawHubContentView {
    var swapSection: some View {
        WithdrawHubSectionView(
            // [REDACTED_TODO_COMMENT]
            title: "Transfer or swap",
            // [REDACTED_TODO_COMMENT]
            subtitle: "From your payment account",
            staticContent: {
                WithdrawHubActionTileView(
                    data: .action(
                        icon: DesignSystem.Icons.ArrowSwapHorizontal.regular20,
                        // [REDACTED_TODO_COMMENT]
                        title: "Within your portfolio",
                        action: { onAction(.withinPortfolioTap) }
                    )
                )
                .disabled(isWithinPortfolioLoading)
            },
            dynamicContent: {
                switch recentTokens {
                case .loading:
                    skeletonTiles

                case .loaded(let items) where items.isEmpty:
                    placeholderTile

                case .loaded(let items):
                    ForEach(items) { item in
                        WithdrawHubActionTileView(
                            data: .recentToken(
                                .init(
                                    tokenIconInfo: item.tokenIconInfo,
                                    name: item.name,
                                    accountIcon: item.accountIcon,
                                    accountName: item.accountName,
                                    action: { onAction(.recentTokenTap(id: item.id)) }
                                )
                            )
                        )
                    }
                }
            }
        )
    }

    var accountsSection: some View {
        WithdrawHubSectionView(
            // [REDACTED_TODO_COMMENT]
            title: "Bank transfer",
            // [REDACTED_TODO_COMMENT]
            subtitle: "Send to another bank using ACH or FedWire",
            staticContent: {
                VStack(spacing: 8) {
                    WithdrawHubCompactActionTileView(
                        icon: Assets.Accounts.user,
                        // [REDACTED_TODO_COMMENT]
                        title: "To personal account",
                        action: { onAction(.personalAccountTap) }
                    )

                    WithdrawHubCompactActionTileView(
                        icon: Assets.Accounts.briefcase,
                        // [REDACTED_TODO_COMMENT]
                        title: "To business account",
                        action: { onAction(.businessAccountTap) }
                    )
                }
            },
            dynamicContent: {
                switch recentAccounts {
                case .loading:
                    skeletonTiles

                case .loaded(let items) where items.isEmpty:
                    placeholderTile

                case .loaded(let items):
                    ForEach(items) { item in
                        WithdrawHubActionTileView(
                            data: .recentAccount(
                                .init(
                                    monogram: item.monogram,
                                    name: item.name,
                                    accountNumber: item.accountNumber,
                                    action: { onAction(.recentAccountTap(id: item.id)) }
                                )
                            )
                        )
                    }

                    WithdrawHubActionTileView(data: .seeAll(action: { onAction(.seeAllTap) }))
                }
            }
        )
    }

    var skeletonTiles: some View {
        ForEach(0 ..< Constants.skeletonTileCount, id: \.self) { _ in
            WithdrawHubActionTileView.Skeleton()
        }
    }

    var placeholderTile: some View {
        WithdrawHubActionTileView(
            data: .placeholder(
                icon: DesignSystem.Icons.Heart.regular20,
                // [REDACTED_TODO_COMMENT]
                title: "Your recent transfers will be here"
            )
        )
    }
}

// MARK: - Constants

private extension WithdrawHubContentView {
    enum Constants {
        static let skeletonTileCount = 3
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Loading") {
    WithdrawHubContentView(
        isWithinPortfolioLoading: false,
        recentTokens: .loading,
        recentAccounts: .loading,
        onAction: { _ in }
    )
    .background { DesignSystem.Color.bgPrimary.ignoresSafeArea() }
}

#Preview("Empty recents") {
    WithdrawHubContentView(
        isWithinPortfolioLoading: false,
        recentTokens: .loaded([]),
        recentAccounts: .loaded([]),
        onAction: { _ in }
    )
    .background { DesignSystem.Color.bgPrimary.ignoresSafeArea() }
}

#Preview("With recents") {
    WithdrawHubContentView(
        isWithinPortfolioLoading: false,
        recentTokens: .loaded([.preview]),
        recentAccounts: .loaded([.preview]),
        onAction: { _ in }
    )
    .background { DesignSystem.Color.bgPrimary.ignoresSafeArea() }
}
#endif
