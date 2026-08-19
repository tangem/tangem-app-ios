//
//  MarketsPortfolioSingleTokenView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets

struct MarketsPortfolioSingleTokenView: View {
    typealias ViewModel = MarketsPortfolioSingleTokenViewModel

    @ObservedObject var viewModel: ViewModel

    @ScaledMetric private var padding: CGFloat = 12
    @ScaledMetric private var backgroundCornerRadius: CGFloat = 20
    @ScaledMetric private var priceWithChangeSpacing: CGFloat = 4

    @ScaledMetric private var scaleFactor: CGFloat = 1

    var body: some View {
        content
            .environment(\.isShimmerActive, true)
    }
}

// MARK: - Subviews

private extension MarketsPortfolioSingleTokenView {
    var content: some View {
        SwiftUI.Button(action: viewModel.onTap) {
            token
                .padding(padding)
                .background(DesignSystem.Color.bgSecondary, in: RoundedRectangle(cornerRadius: backgroundCornerRadius))
        }
        .buttonStyle(.plain)
    }

    var token: some View {
        TwoLineRowWithIcon(
            icon: icon,
            primaryLeadingView: tokenName,
            primaryTrailingView: fiatBalance,
            secondaryLeadingView: priceWithChange,
            secondaryTrailingView: cryptoBalance
        )
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

    func priceWithChange() -> some View {
        HStack(spacing: priceWithChangeSpacing) {
            LoadableTextView(
                state: viewModel.priceWithChangeState.priceState,
                font: DesignSystem.Font.captionMediumToken.font,
                textColor: DesignSystem.Color.textSecondary,
                loaderSize: CGSize(width: 52, height: 12) * scaleFactor
            )

            PriceChangeView(
                state: viewModel.priceWithChangeState.changeState,
                showSkeletonWhenLoading: false
            )
        }
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
