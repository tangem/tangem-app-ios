//
//  MarketsPortfolioSingleTokenView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct MarketsPortfolioSingleTokenView: View {
    typealias ViewModel = MarketsPortfolioSingleTokenViewModel

    @ObservedObject var viewModel: ViewModel

    @ScaledMetric private var padding: CGFloat = .unit(.x3)
    @ScaledMetric private var backgroundCornerRadius: CGFloat = .unit(.x5)
    @ScaledMetric private var priceWithChangeSpacing: CGFloat = .unit(.x1)
    @ScaledSize private var tokenIconSize = CGSize(width: .unit(.x10), height: .unit(.x10))
    @ScaledSize private var priceLoaderSize = CGSize(width: .unit(.x13), height: .unit(.x3))
    @ScaledSize private var fiatBalanceSkeletonSize = CGSize(width: .unit(.x16), height: .unit(.x5))
    @ScaledSize private var cryptoBalanceSkeletonSize = CGSize(width: .unit(.x13), height: .unit(.x4))

    var body: some View {
        content
            .environment(\.isShimmerActive, true)
    }
}

// MARK: - Subviews

private extension MarketsPortfolioSingleTokenView {
    var content: some View {
        Button(action: viewModel.onTap) {
            token
                .padding(padding)
                .background(Color.Tangem.Surface.level3, in: RoundedRectangle(cornerRadius: backgroundCornerRadius))
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
            size: tokenIconSize
        )
    }

    func tokenName() -> some View {
        Text(viewModel.tokenName)
            .style(.Tangem.Body16.medium, color: .Tangem.Text.Neutral.primary)
            .lineLimit(1)
    }

    func fiatBalance() -> some View {
        balanceState(viewModel.fiatBalanceState, skeletonSize: fiatBalanceSkeletonSize)
    }

    func priceWithChange() -> some View {
        HStack(spacing: priceWithChangeSpacing) {
            LoadableTextView(
                state: viewModel.priceWithChangeState.priceState,
                font: Fonts.Regular.caption1,
                textColor: Colors.Text.tertiary,
                loaderSize: priceLoaderSize
            )

            PriceChangeView(
                state: viewModel.priceWithChangeState.changeState,
                showSkeletonWhenLoading: false
            )
        }
    }

    func cryptoBalance() -> some View {
        balanceState(viewModel.cryptoBalanceState, skeletonSize: cryptoBalanceSkeletonSize)
    }

    func balanceState(_ state: ViewModel.BalanceState, skeletonSize: CGSize) -> some View {
        MarketsPortfolioTokenBalanceView(
            state: state,
            skeletonSize: skeletonSize
        )
    }
}
