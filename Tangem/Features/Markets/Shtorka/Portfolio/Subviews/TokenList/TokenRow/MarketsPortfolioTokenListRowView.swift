//
//  MarketsPortfolioTokenListRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets

struct MarketsPortfolioTokenListRowView: View {
    typealias ViewModel = MarketsPortfolioTokenListRowViewModel

    @ObservedObject var viewModel: ViewModel

    @ScaledMetric private var scaleFactor: CGFloat = 1

    var body: some View {
        content
            .contentShape(.rect)
            .environment(\.isShimmerActive, true)
    }
}

// MARK: - Subviews

private extension MarketsPortfolioTokenListRowView {
    @ViewBuilder
    var content: some View {
        if viewModel.isNoAddress {
            TangemTwoLineRowLayout(
                icon: icon,
                primaryLeading: tokenName,
                primaryTrailing: noAddressLabel,
                secondaryLeading: networkName,
                secondaryTrailing: emptyTrailing
            )
        } else {
            TangemTwoLineRowLayout(
                icon: icon,
                primaryLeading: tokenName,
                primaryTrailing: fiatBalance,
                secondaryLeading: networkName,
                secondaryTrailing: cryptoBalance
            )
        }
    }

    func noAddressLabel() -> some View {
        Text(viewModel.noAddressText)
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            .lineLimit(1)
    }

    func emptyTrailing() -> some View {
        EmptyView()
    }

    func icon() -> some View {
        TokenIcon(
            tokenIconInfo: viewModel.tokenIconInfo,
            size: CGSize(width: 40, height: 40) * scaleFactor
        )
    }

    func tokenName() -> some View {
        Text(viewModel.tokenName)
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
            .lineLimit(1)
    }

    func fiatBalance() -> some View {
        balanceState(viewModel.fiatBalanceState, skeletonSize: CGSize(width: 64, height: 20) * scaleFactor)
    }

    func networkName() -> some View {
        Text(viewModel.networkName)
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            .lineLimit(1)
    }

    func cryptoBalance() -> some View {
        balanceState(viewModel.cryptoBalanceState, skeletonSize: CGSize(width: 52, height: 16) * scaleFactor)
    }

    func balanceState(_ state: ViewModel.BalanceState, skeletonSize: CGSize) -> some View {
        MarketsPortfolioTokenBalanceView(
            state: state,
            skeletonSize: skeletonSize
        )
    }
}
