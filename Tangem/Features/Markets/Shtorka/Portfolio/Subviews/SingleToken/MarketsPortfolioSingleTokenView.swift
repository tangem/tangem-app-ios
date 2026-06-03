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

    @ScaledMetric private var padding: CGFloat = .unit(.x3)
    @ScaledMetric private var backgroundCornerRadius: CGFloat = .unit(.x5)
    @ScaledMetric private var priceWithChangeSpacing: CGFloat = .unit(.x1)

    @ScaledMetric private var scaleFactor: CGFloat = 1

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
            size: CGSize(width: .unit(.x10), height: .unit(.x10)) * scaleFactor
        )
    }

    func tokenName() -> some View {
        Text(viewModel.tokenName)
            .style(.Tangem.Body16.medium, color: .Tangem.Text.Neutral.primary)
            .lineLimit(1)
    }

    func fiatBalance() -> some View {
        balanceState(viewModel.fiatBalanceState, skeletonSize: CGSize(width: .unit(.x16), height: .unit(.x5)) * scaleFactor)
    }

    func priceWithChange() -> some View {
        HStack(spacing: priceWithChangeSpacing) {
            LoadableTextView(
                state: viewModel.priceWithChangeState.priceState,
                font: Fonts.Regular.caption1,
                textColor: Colors.Text.tertiary,
                loaderSize: CGSize(width: .unit(.x13), height: .unit(.x3)) * scaleFactor
            )

            PriceChangeView(
                state: viewModel.priceWithChangeState.changeState,
                showSkeletonWhenLoading: false
            )
        }
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
