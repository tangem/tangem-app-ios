//
//  PulseView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemUI

struct PulseView: View {
    @ObservedObject var viewModel: PulseViewModel
    @ScaledMetric(relativeTo: .subheadline) private var controlHeight: CGFloat = 36
    @ScaledMetric private var filterHeight: CGFloat = 36
    @ScaledMetric private var filterIconSize: CGFloat = 16

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
                .padding(.horizontal, Constants.horizontalPadding)

            categoriesRow

            // The states overlap while fading so they dissolve in place instead of pushing each other
            ZStack(alignment: .topLeading) {
                tokensContent
                    .id(viewModel.contentState)
                    .transition(.content)
            }
        }
        .onAppear(perform: viewModel.onViewAppear)
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.3), value: viewModel.selectedTag)
        .animation(.contentFrameUpdate, value: viewModel.contentState)
    }

    @ViewBuilder
    private var tokensContent: some View {
        switch viewModel.contentState {
        case .failure:
            TangemUnableToLoadDataView(isButtonBusy: false, retryButtonAction: viewModel.onRetry)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Constants.errorVerticalPadding)

        case .skeletons:
            loadingSkeletons

        case .empty:
            Text(Localization.marketsSearchTokenNoResultTitle)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Constants.errorVerticalPadding)

        case .rows:
            LazyVStack(spacing: 0) {
                ForEach(viewModel.tokens) { token in
                    MarketTokenRowView(viewModel: token)
                        .onAppear { viewModel.onTokenAppear(token) }
                        .onDisappear { viewModel.onTokenDisappear(token) }
                }
            }
        }
    }

    private var loadingSkeletons: some View {
        LazyVStack(spacing: 0) {
            ForEach(0 ..< Constants.skeletonRowCount, id: \.self) { _ in
                TokenRowMarket(.shimmer)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.marketsPulseCommonTitle)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)

            HStack(spacing: 0) {
                tagChip

                Spacer(minLength: Constants.tagChipMinimumSpacing)

                intervalDropDown
            }
        }
    }

    private var intervalDropDown: some View {
        TangemDropDown(items: viewModel.intervals.map { interval in
            TangemDropDownItem(
                id: interval,
                text: PulseIntervalOption(interval: interval).text,
                isChecked: interval == viewModel.selectedInterval,
                accessibilityIdentifier: MarketsAccessibilityIdentifiers.marketsIntervalSegment(interval.rawValue),
                action: { viewModel.onSelectInterval(interval) }
            )
        }) {
            HStack(spacing: 4) {
                Text(PulseIntervalOption(interval: viewModel.selectedInterval).text)
                    .lineLimit(1)

                DesignSystem.Icons.ChevronDown.regular16.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: filterIconSize, height: filterIconSize)
            }
            .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
            .padding(.leading, 12)
            .padding(.trailing, 10)
            .frame(height: filterHeight)
            .background(DesignSystem.Color.bgOpaqueSecondary, in: .capsule)
        }
        .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsIntervalButton(viewModel.selectedInterval.rawValue))
        .fixedSize(horizontal: true, vertical: false)
    }

    private var tagChip: some View {
        RealAssetsCategoryChipView(
            title: viewModel.tagChipTitle,
            style: viewModel.selectedTag == nil ? .expandable : .selected,
            onTap: viewModel.onTagChipTap,
            onClear: viewModel.onTagClearTap
        )
        .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsPulseTagChip)
    }

    private var categoriesRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(viewModel.categories, id: \.self) { category in
                    categoryChip(category)
                }
            }
            .padding(.horizontal, Constants.horizontalPadding)
        }
    }

    private func categoryChip(_ category: PulseCategory) -> some View {
        let isSelected = category == viewModel.selectedCategory

        return SwiftUI.Button {
            guard !isSelected else { return }

            FeedbackGenerator.selection()
            viewModel.onSelectCategory(category)
        } label: {
            chip(category.title, isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsSortOption(category.accessibilityOrderId))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func chip(_ title: String, isSelected: Bool) -> some View {
        Text(title)
            .style(
                DesignSystem.Font.subheadingMediumToken,
                color: isSelected ? DesignSystem.Color.textPrimary : DesignSystem.Color.textSecondary
            )
            .lineLimit(1)
            .padding(.horizontal, 12)
            .frame(minHeight: controlHeight)
            .background {
                if isSelected {
                    Capsule().fill(DesignSystem.Color.bgOpaqueSecondary)
                }
            }
    }
}

private extension PulseCategory {
    var accessibilityOrderId: String {
        switch self {
        case .marketCap: MarketsListOrderType.rating.rawValue
        case .topGainers: MarketsListOrderType.gainers.rawValue
        case .topLosers: MarketsListOrderType.losers.rawValue
        case .experiencedBuyers: MarketsListOrderType.buyers.rawValue
        case .trending: MarketsListOrderType.trending.rawValue
        }
    }
}

private struct PulseIntervalOption: TangemDropDownTextProvider {
    let interval: PulseInterval

    var text: String {
        interval.title
    }
}

// MARK: - Constants

private extension PulseView {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let tagChipMinimumSpacing: CGFloat = 8
        static let skeletonRowCount = 20
        static let errorVerticalPadding: CGFloat = 24
    }
}

// MARK: - Content transition

private extension Animation {
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.3)
}

private extension AnyTransition {
    static let content = AnyTransition.opacity.animation(.curve(.easeInOutRefined, duration: 0.3))
}
