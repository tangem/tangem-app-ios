//
//  WithdrawHubContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct WithdrawHubContentView: View {
    let isWithinPortfolioLoading: Bool
    let recentTokens: WithdrawHubSectionState<WithdrawHubRecentTokenItem>
    let recentAccounts: WithdrawHubSectionState<WithdrawHubRecentAccountItem>
    let isSeeAllAccountsVisible: Bool
    let bankTransferState: WithdrawHubViewModel.BankTransferState
    let onAction: (WithdrawHubViewModel.ViewAction) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                swapSection

                accountsSection

                Spacer()
            }
            .padding(.vertical, 12)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

// MARK: - Subviews

private extension WithdrawHubContentView {
    var swapSection: some View {
        WithdrawHubSectionView(
            title: Localization.tangempayWithdrawHubSwapSectionTitle,
            subtitle: Localization.tangempayWithdrawHubSwapSectionSubtitle,
            staticContent: {
                WithdrawHubActionTileView(
                    data: .action(
                        icon: DesignSystem.Icons.ArrowSwapHorizontal.regular20,
                        title: Localization.tangempayWithdrawHubWithinPortfolio,
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

                case .failed:
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
            title: Localization.tangempayWithdrawHubBankSectionTitle,
            subtitle: accountsSubtitle,
            subtitleColor: accountsSubtitleColor,
            staticContent: {
                VStack(spacing: 8) {
                    WithdrawHubCompactActionTileView(
                        icon: Assets.Accounts.user,
                        title: Localization.tangempayWithdrawHubToPersonalAccount,
                        action: { onAction(.personalAccountTap) }
                    )

                    WithdrawHubCompactActionTileView(
                        icon: Assets.Accounts.briefcase,
                        title: Localization.tangempayWithdrawHubToBusinessAccount,
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

                case .failed:
                    retryTile

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

                    if isSeeAllAccountsVisible {
                        WithdrawHubActionTileView(data: .seeAll(action: { onAction(.seeAllTap) }))
                            .transition(.content)
                    }
                }
            }
        )
        .disabled(!bankTransferState.isEnabled)
        .animation(.contentUpdate, value: recentAccounts.contentID)
        .animation(.contentUpdate, value: isSeeAllAccountsVisible)
    }

    var accountsSubtitle: String {
        switch bankTransferState {
        case .loading, .available:
            Localization.tangempayWithdrawHubBankSectionSubtitle
        case .unavailable:
            Localization.tangempayWithdrawHubBankSectionSubtitleUnavailable
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

    var retryTile: some View {
        WithdrawHubActionTileView(
            data: .retry(
                title: Localization.tangempayWithdrawHubAccountsLoadError,
                action: { onAction(.retryRecentAccountsTap) }
            )
        )
        .transition(.content)
    }

    var placeholderTile: some View {
        WithdrawHubActionTileView(
            data: .placeholder(
                icon: DesignSystem.Icons.Heart.regular20,
                title: Localization.tangempayWithdrawHubRecentsEmpty
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
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Loading") {
    WithdrawHubContentView(
        isWithinPortfolioLoading: false,
        recentTokens: .loading,
        recentAccounts: .loading,
        isSeeAllAccountsVisible: false,
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
        isSeeAllAccountsVisible: false,
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
        isSeeAllAccountsVisible: false,
        bankTransferState: .available,
        onAction: { _ in }
    )
    .background { DesignSystem.Color.bgPrimary.ignoresSafeArea() }
}

#Preview("With recents and See all") {
    WithdrawHubContentView(
        isWithinPortfolioLoading: false,
        recentTokens: .loaded([.preview]),
        recentAccounts: .loaded([.preview, .preview2, .preview3]),
        isSeeAllAccountsVisible: true,
        bankTransferState: .available,
        onAction: { _ in }
    )
    .background { DesignSystem.Color.bgPrimary.ignoresSafeArea() }
}

#Preview("Bank accounts failed") {
    WithdrawHubContentView(
        isWithinPortfolioLoading: false,
        recentTokens: .loaded([]),
        recentAccounts: .failed,
        isSeeAllAccountsVisible: false,
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
        isSeeAllAccountsVisible: false,
        bankTransferState: .unavailable,
        onAction: { _ in }
    )
    .background { DesignSystem.Color.bgPrimary.ignoresSafeArea() }
}
#endif
