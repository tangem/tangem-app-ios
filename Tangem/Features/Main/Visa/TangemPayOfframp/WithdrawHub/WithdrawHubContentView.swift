//
//  WithdrawHubContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct WithdrawHubContentView: View {
    let isWithinPortfolioLoading: Bool
    let recentTokens: WithdrawHubSectionState<WithdrawHubRecentTokenItem>
    let recentAccounts: WithdrawHubSectionState<WithdrawHubRecentAccountItem>
    let bankTransferState: WithdrawHubViewModel.BankTransferState
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
                    .transition(.content)
                }
            }
        )
        .animation(.contentUpdate, value: recentTokens.contentID)
    }

    var accountsSection: some View {
        WithdrawHubSectionView(
            // [REDACTED_TODO_COMMENT]
            title: "Bank transfer",
            subtitle: accountsSubtitle,
            subtitleColor: accountsSubtitleColor,
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
                    .transition(.content)

                    WithdrawHubActionTileView(data: .seeAll(action: { onAction(.seeAllTap) }))
                        .transition(.content)
                }
            }
        )
        .disabled(!bankTransferState.isEnabled)
        .animation(.contentUpdate, value: recentAccounts.contentID)
    }

    var accountsSubtitle: String {
        switch bankTransferState {
        case .loading, .available:
            Constants.accountsSubtitle
        case .unavailable:
            Constants.accountsUnavailableSubtitle
        }
    }

    var accountsSubtitleColor: Color {
        switch bankTransferState {
        case .loading, .available:
            DesignSystem.Color.textSecondary
        case .unavailable:
            DesignSystem.Color.textStatusWarning
        }
    }

    var skeletonTiles: some View {
        ForEach(0 ..< Constants.skeletonTileCount, id: \.self) { _ in
            WithdrawHubActionTileView.Skeleton()
        }
        .transition(.content)
    }

    var placeholderTile: some View {
        WithdrawHubActionTileView(
            data: .placeholder(
                icon: DesignSystem.Icons.Heart.regular20,
                // [REDACTED_TODO_COMMENT]
                title: "Your recent transfers will be here"
            )
        )
        .transition(.content)
    }
}

// MARK: - Animations and Transitions

private extension Animation {
    static let contentUpdate = Animation.curve(.easeInOutRefined, duration: 0.3)
}

private extension AnyTransition {
    static let content = AnyTransition.asymmetric(
        insertion: .opacity.animation(.curve(.easeInOutRefined, duration: 0.2).delay(0.15)),
        removal: .opacity.animation(.curve(.easeInOutRefined, duration: 0.15))
    )
}

// MARK: - Constants

private extension WithdrawHubContentView {
    enum Constants {
        static let skeletonTileCount = 3

        // [REDACTED_TODO_COMMENT]
        static let accountsSubtitle = "Send to another bank using ACH or FedWire"
        // [REDACTED_TODO_COMMENT]
        static let accountsUnavailableSubtitle = "Available only for USDC on Polygon, Base, Arbitrum"
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Loading") {
    WithdrawHubContentView(
        isWithinPortfolioLoading: false,
        recentTokens: .loading,
        recentAccounts: .loading,
        bankTransferState: .loading,
        onAction: { _ in }
    )
    .background { DesignSystem.Color.bgPrimary.ignoresSafeArea() }
}

#Preview("Empty recents") {
    WithdrawHubContentView(
        isWithinPortfolioLoading: false,
        recentTokens: .loaded([]),
        recentAccounts: .loaded([]),
        bankTransferState: .available,
        onAction: { _ in }
    )
    .background { DesignSystem.Color.bgPrimary.ignoresSafeArea() }
}

#Preview("With recents") {
    WithdrawHubContentView(
        isWithinPortfolioLoading: false,
        recentTokens: .loaded([.preview]),
        recentAccounts: .loaded([.preview]),
        bankTransferState: .available,
        onAction: { _ in }
    )
    .background { DesignSystem.Color.bgPrimary.ignoresSafeArea() }
}

#Preview("Bank transfer unavailable") {
    WithdrawHubContentView(
        isWithinPortfolioLoading: false,
        recentTokens: .loaded([.preview]),
        recentAccounts: .loaded([.preview]),
        bankTransferState: .unavailable,
        onAction: { _ in }
    )
    .background { DesignSystem.Color.bgPrimary.ignoresSafeArea() }
}
#endif
