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
        .infinityFrame(axis: .horizontal, alignment: .leading)
    }

    @ViewBuilder
    var subtitleView: some View {
        switch viewModel.state {
        case .loading:
            subtitleShimmer
        case .content(let content):
            if let subtitle = content.subtitle {
                self.subtitle(subtitle)
            }
        }
    }

    @ViewBuilder
    func content(for state: EarnOpportunitiesViewModel.ViewState) -> some View {
        switch state {
        case .loading:
            skeletonAccounts
        case .content(let content):
            LazyVStack(spacing: 8) {
                listContent(content.list)
                exploreButton
            }
        }
    }

    @ViewBuilder
    func listContent(_ list: EarnOpportunitiesViewModel.ViewState.List) -> some View {
        switch list {
        case .accounts(let accounts):
            ForEach(accounts) { account in
                EarnAccountItemView(item: account, onAccountTap: viewModel.toggle)
            }
        case .suggestions(let suggestions):
            ForEach(suggestions) { suggestion in
                EarnSuggestionRowView(data: suggestion)
            }
        }
    }

    // MARK: - Subtitle

    @ViewBuilder
    func subtitle(_ subtitle: EarnRewardSubtitle) -> some View {
        if let chip = subtitle.chip {
            // The chip row cannot wrap — single line keeps the text and the chip on one baseline.
            HStack(spacing: 4) {
                subtitleText(subtitle.prefix, lineLimit: 1)

                rewardChip(chip)

                if let suffix = subtitle.suffix {
                    subtitleText(suffix, lineLimit: 1)
                }
            }
            .infinityFrame(axis: .horizontal, alignment: .leading)
        } else {
            subtitleText(subtitle.prefix, lineLimit: nil)
                .infinityFrame(axis: .horizontal, alignment: .leading)
        }
    }

    func subtitleText(_ text: String, lineLimit: Int?) -> some View {
        Text(text)
            .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
            .lineLimit(lineLimit)
    }

    func rewardChip(_ text: String) -> some View {
        Text(text)
            .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
            .lineLimit(1)
            .padding(.horizontal, 4)
            .background(DesignSystem.Color.iconBrand, in: RoundedRectangle(cornerRadius: 6))
    }

    var subtitleShimmer: some View {
        Shimmer()
            .variant(.text(style: .headingSmall))
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
        TangemUI.Button(
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
            EarnOpportunitiesView(viewModel: EarnOpportunitiesViewModel(state: .preview))
            EarnOpportunitiesView(viewModel: EarnOpportunitiesViewModel(state: .previewSuggestions))
            EarnOpportunitiesView(viewModel: EarnOpportunitiesViewModel(state: .loading))
        }
        .padding(16)
    }
    .background(DesignSystem.Color.bgPrimary)
}
