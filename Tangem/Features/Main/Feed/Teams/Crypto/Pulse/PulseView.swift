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
import TangemLocalization
import TangemUI

struct PulseView: View {
    @ObservedObject var viewModel: PulseViewModel
    @ScaledMetric(relativeTo: .subheadline) private var controlHeight: CGFloat = 36

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
                .padding(.horizontal, Constants.horizontalPadding)

            categoriesRow

            tokensContent
                .background(DesignSystem.Color.bgSecondary, in: RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, Constants.horizontalPadding)
        }
        .onAppear(perform: viewModel.onViewAppear)
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.3), value: viewModel.selectedTag)
    }

    @ViewBuilder
    private var tokensContent: some View {
        if viewModel.isFailed, viewModel.tokens.isEmpty {
            TangemUnableToLoadDataView(isButtonBusy: false, retryButtonAction: viewModel.onRetry)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Constants.errorVerticalPadding)
        } else if viewModel.tokens.isEmpty, viewModel.isLoading {
            LazyVStack(spacing: 0) {
                ForEach(0 ..< Constants.skeletonRowCount, id: \.self) { _ in
                    TokenRowMarket(.shimmer)
                }
            }
        } else if viewModel.tokens.isEmpty {
            Text(Localization.marketsSearchTokenNoResultTitle)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Constants.errorVerticalPadding)
        } else {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.tokens) { token in
                    MarketTokenRowView(viewModel: token)
                        .onAppear { viewModel.onTokenAppear(token) }
                        .onDisappear { viewModel.onTokenDisappear(token) }
                }
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
        TangemDropDown(
            singleSelection: Binding(
                get: { PulseIntervalOption(interval: viewModel.selectedInterval) },
                set: { viewModel.onSelectInterval($0.interval) }
            ),
            in: viewModel.intervals.map(PulseIntervalOption.init)
        )
        .accessibilityIdentifier { option in
            MarketsAccessibilityIdentifiers.marketsIntervalSegment(option.interval.rawValue)
        }
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
                    SwiftUI.Button {
                        viewModel.onSelectCategory(category)
                    } label: {
                        chip(category.title, isSelected: category == viewModel.selectedCategory)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Constants.horizontalPadding)
        }
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
