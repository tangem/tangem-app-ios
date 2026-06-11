//
//  MarketsPortfolioMultipleTokenView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets

struct MarketsPortfolioMultipleTokenView: View {
    typealias ViewModel = MarketsPortfolioMultipleTokenViewModel

    @ObservedObject var viewModel: ViewModel

    @ScaledMetric private var padding: CGFloat = .unit(.x3)
    @ScaledMetric private var horizontalSpacing: CGFloat = .unit(.x3)
    @ScaledMetric private var backgroundCornerRadius: CGFloat = .unit(.x5)
    @ScaledMetric private var tokenIconSetWidth: CGFloat = .unit(.x12)
    @ScaledMetric private var tokenIconSide = CGFloat.unit(.x10)
    @ScaledMetric private var scaleFactor: CGFloat = 1

    var body: some View {
        content
            .environment(\.isShimmerActive, true)
    }
}

// MARK: - Subviews

private extension MarketsPortfolioMultipleTokenView {
    var content: some View {
        Button(action: viewModel.onTap) {
            HStack(spacing: horizontalSpacing) {
                token
                arrow
            }
            .padding(padding)
            .background(Color.Tangem.Surface.level3, in: RoundedRectangle(cornerRadius: backgroundCornerRadius))
        }
        .buttonStyle(.plain)
    }

    var token: some View {
        TwoLineRowWithIcon(
            icon: iconSet,
            primaryLeadingView: tokenName,
            primaryTrailingView: fiatBalance,
            secondaryLeadingView: tokensCount,
            secondaryTrailingView: cryptoBalance
        )
    }

    var arrow: some View {
        TangemButton(
            content: .icon(Assets.DesignSystem.chevronDown),
            action: viewModel.onTap
        )
        .setStyleType(.secondary)
        .setCornerStyle(.rounded)
        .setSize(.x9)
        .allowsHitTesting(false)
    }

    func iconSet() -> some View {
        let icon = TokenIcon(
            tokenIconInfo: viewModel.tokenIconInfo,
            size: CGSize(width: tokenIconSide, height: tokenIconSide),
            isWithOverlays: false
        )

        let offsetStep = viewModel.tokenIconSetOffset(
            totalWidth: tokenIconSetWidth,
            iconWidth: tokenIconSide
        )

        return ZStack {
            ForEach(viewModel.tokenIconSetRange, id: \.self) { index in
                let opacity = pow(0.4, Double(index))
                let offset = offsetStep * CGFloat(index)
                let zIndex = Double(-index)

                icon
                    .opacity(opacity)
                    .offset(x: offset)
                    .zIndex(zIndex)
            }
        }
    }

    func tokenName() -> some View {
        Text(viewModel.tokenName)
            .style(.Tangem.Body16.medium, color: .Tangem.Text.Neutral.primary)
            .lineLimit(1)
    }

    func fiatBalance() -> some View {
        balanceState(viewModel.fiatBalanceState, skeletonSize: CGSize(width: .unit(.x16), height: .unit(.x5)) * scaleFactor)
    }

    func tokensCount() -> some View {
        Text(viewModel.tokensCount)
            .style(.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.secondary)
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
