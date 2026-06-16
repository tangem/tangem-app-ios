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
    var content: some View {
        TangemTwoLineRowLayout(
            icon: icon,
            primaryLeading: tokenName,
            primaryTrailing: fiatBalance,
            secondaryLeading: networkName,
            secondaryTrailing: cryptoBalance
        )
    }

    func icon() -> some View {
        TokenIcon(
            tokenIconInfo: viewModel.tokenIconInfo,
            size: CGSize(width: .unit(.x10), height: .unit(.x10)) * scaleFactor
        )
    }

    func tokenName() -> some View {
        Text(viewModel.tokenName)
            .style(Font.Tangem.Body16.medium, color: .Tangem.Text.Neutral.primary)
            .lineLimit(1)
    }

    func fiatBalance() -> some View {
        balanceState(viewModel.fiatBalanceState, skeletonSize: CGSize(width: .unit(.x16), height: .unit(.x5)) * scaleFactor)
    }

    func networkName() -> some View {
        Text(viewModel.networkName)
            .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.secondary)
            .lineLimit(1)
    }

    func cryptoBalance() -> some View {
        balanceState(viewModel.cryptoBalanceState, skeletonSize: CGSize(width: .unit(.x13), height: .unit(.x4)) * scaleFactor)
    }

    func balanceState(_ state: ViewModel.BalanceState, skeletonSize: CGSize) -> some View {
        MarketsPortfolioTokenBalanceView(
            state: state,
            skeletonSize: skeletonSize
        )
    }
}
