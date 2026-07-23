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

    @ScaledMetric private var padding: CGFloat = 12
    @ScaledMetric private var horizontalSpacing: CGFloat = 12
    @ScaledMetric private var backgroundCornerRadius: CGFloat = 20
    @ScaledMetric private var tokenIconSetWidth: CGFloat = 48
    @ScaledMetric private var tokenIconSide: CGFloat = 40
    @ScaledMetric private var scaleFactor: CGFloat = 1

    var body: some View {
        content
            .environment(\.isShimmerActive, true)
    }
}

// MARK: - Subviews

private extension MarketsPortfolioMultipleTokenView {
    var content: some View {
        SwiftUI.Button(action: viewModel.onTap) {
            HStack(spacing: horizontalSpacing) {
                token
                arrow
            }
            .padding(padding)
            .background(DesignSystem.Color.bgSecondary, in: RoundedRectangle(cornerRadius: backgroundCornerRadius))
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
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
            .lineLimit(1)
    }

    func fiatBalance() -> some View {
        balanceState(viewModel.fiatBalanceState, skeletonSize: CGSize(width: 64, height: 20) * scaleFactor)
    }

    func tokensCount() -> some View {
        Text(viewModel.tokensCount)
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
