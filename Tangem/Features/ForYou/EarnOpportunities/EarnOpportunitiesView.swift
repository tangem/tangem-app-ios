//
//  EarnOpportunitiesView.swift
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

struct EarnOpportunitiesView: View {
    @ObservedObject var viewModel: EarnOpportunitiesViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerBlock
            content(for: viewModel.state)
        }
    }
}

private extension EarnOpportunitiesView {
    // MARK: - View properties

    var headerBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Localization.forYouEarnOpportunities)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textSecondary)

            subtitleView
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    var subtitleView: some View {
        switch viewModel.state {
        case .loading:
            subtitleShimmer
        case .content(let content):
            subtitle(content.subtitle)
        }
    }

    @ViewBuilder
    func content(for state: EarnOpportunitiesViewModel.ViewState) -> some View {
        switch state {
        case .loading:
            skeletonAccounts
        case .content(let content):
            LazyVStack(spacing: 8) {
                ForEach(content.accounts) { account in
                    EarnAccountItemView(item: account, onAccountTap: viewModel.toggle)
                }
                exploreButton
            }
        }
    }

    // MARK: - Subtitle

    func subtitle(_ subtitle: EarnRewardSubtitle) -> some View {
        HStack(spacing: 4) {
            subtitleText(subtitle.label)
            rewardChip(subtitle.amount)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func subtitleText(_ text: String) -> some View {
        Text(text)
            .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
            .lineLimit(1)
    }

    func rewardChip(_ text: String) -> some View {
        Text(text)
            .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
            .lineLimit(1)
            .padding(.horizontal, 4)
            .background(DesignSystem.Color.iconBrand, in: RoundedRectangle(cornerRadius: 6))
    }

    var subtitleShimmer: some View {
        TangemShimmer()
            .variant(.custom(height: 20, cornerRadius: 10))
            .frame(width: 180)
    }

    // MARK: - Loading

    var skeletonAccounts: some View {
        VStack(spacing: 8) {
            ForEach(0 ..< 3, id: \.self) { _ in
                TangemTwoLineRowSkeletonView()
                    .portfolioTokenCard()
            }
        }
    }

    // MARK: - Explore button

    var exploreButton: some View {
        TangemButtonV2(
            label: AttributedString(Localization.forYouEarnOpportunitiesExplore),
            accessibilityLabel: Localization.forYouEarnOpportunitiesExplore,
            action: viewModel.exploreAllTokensTapped
        )
        .size(.x9)
        .styleType(.secondary)
        .horizontalLayout(.infinity)
    }
}

// MARK: - Previews

#Preview {
    ScrollView {
        VStack(spacing: 32) {
            EarnOpportunitiesView(viewModel: EarnOpportunitiesViewModel(state: .mock))
            EarnOpportunitiesView(viewModel: EarnOpportunitiesViewModel(state: .loading))
        }
        .padding(16)
    }
    .background(DesignSystem.Color.bgPrimary)
}
