//
//  PortfolioReviewView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct PortfolioReviewView: View {
    @ObservedObject var viewModel: PortfolioReviewViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            content
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.state == .loading)
    }
}

private extension PortfolioReviewView {
    var header: some View {
        HStack(spacing: 8) {
            Text(Localization.forYouPortfolioReviewTitle)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)

            Spacer(minLength: 8)

            allAccountsBadge
        }
    }

    // [REDACTED_TODO_COMMENT]
    var allAccountsBadge: some View {
        Badge(label: Localization.commonAllAccounts, accessibilityLabel: Localization.commonAllAccounts)
            .size(.x9)
            .variant(.solid)
            .slotEnd(DesignSystem.Icons.ChevronDown.regular16)
    }

    var content: some View {
        VStack(spacing: 8) {
            stateContent
                .transition(.opacity)
        }
    }

    @ViewBuilder
    var stateContent: some View {
        switch viewModel.state {
        case .loading:
            chartCardSkeleton
            periodPickerShimmer
            skeletonList
        case .content(let content):
            PortfolioReviewChartCardView(chart: content.chart, selectedID: $viewModel.selectedChartSegmentID)
            ForYouPeriodPickerView(
                segments: content.periodSegments,
                selection: $viewModel.selectedPeriod
            )
            tokenList(content.tokenList)
            if content.showsAddFunds {
                addFundsButton
            }
        }
    }

    var addFundsButton: some View {
        TangemUI.Button(
            label: AttributedString(Localization.commonAddFunds),
            accessibilityLabel: Localization.commonAddFunds,
            action: viewModel.addFundsTapped
        )
        .size(.x9)
        .styleType(.secondary)
        .horizontalLayout(.infinity)
    }

    var periodPickerShimmer: some View {
        Shimmer()
            .variant(.custom(height: 40, cornerRadius: 20))
            .frame(maxWidth: .infinity)
    }

    /// Loading placeholder matching the chart card's size/layout (donut ring 200 + summary + AI lines).
    var chartCardSkeleton: some View {
        VStack(alignment: .leading, spacing: 16) {
            Shimmer()
                .variant(.custom(height: 200, cornerRadius: 100))
                .frame(width: 200)
                .mask { Circle().strokeBorder(lineWidth: 28) }
                .padding(32)
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 8) {
                shimmerBar(width: 90)
                shimmerBar(width: 200)
            }
            .padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 8) {
                shimmerBar(width: 260)
                shimmerBar(width: 170)
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 16)
        .portfolioTokenCard()
    }

    func shimmerBar(width: CGFloat) -> some View {
        Shimmer()
            .variant(.custom(height: 20, cornerRadius: 10))
            .frame(width: width)
    }

    var skeletonList: some View {
        VStack(spacing: 8) {
            ForEach(0 ..< 4, id: \.self) { _ in
                TangemTwoLineRowSkeletonView()
                    .portfolioTokenCard()
            }
        }
    }

    func tokenList(_ items: [ForYouTokenListItem]) -> some View {
        LazyVStack(spacing: 8) {
            ForEach(items) { item in
                PortfolioTokenItemView(item: item, onAssetTap: viewModel.toggle, onTokenSelect: viewModel.selectToken)
            }
        }
    }
}
