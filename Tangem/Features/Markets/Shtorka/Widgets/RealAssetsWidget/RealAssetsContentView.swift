//
//  RealAssetsContentView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct RealAssetsContentView: View {
    @ObservedObject var viewModel: RealAssetsWidgetViewModel

    @ScaledMetric private var bannerIconSize: CGFloat = 20
    @ScaledMetric(relativeTo: .subheadline) private var orderChipHeight: CGFloat = 36

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.contentSpacing) {
            if let featuredViewModel = viewModel.featuredViewModel {
                RealAssetsFeaturedView(viewModel: featuredViewModel)
                    .padding(.horizontal, Layout.contentHorizontalPadding)
            }

            filters

            if viewModel.isRegionRestrictionBannerVisible {
                regionRestrictionBanner
                    .padding(.horizontal, Layout.contentHorizontalPadding)
            }

            list
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.tokenListLoadingState)
        .animation(.easeInOut(duration: 0.3), value: viewModel.categorySelection)
    }

    @ViewBuilder
    private var filters: some View {
        if let selection = viewModel.categorySelection {
            VStack(alignment: .leading, spacing: Layout.contentSpacing) {
                HStack(spacing: Layout.contentSpacing) {
                    RealAssetsCategoryChipView(
                        title: selection.title,
                        style: selection.isUmbrella ? .expandable : .selected,
                        onTap: viewModel.onCategoryChipTap,
                        onClear: viewModel.onCategoryClearTap
                    )

                    Spacer(minLength: .zero)

                    intervalDropDown
                }
                .padding(.horizontal, Layout.contentHorizontalPadding)

                orderChips
            }
        }
    }

    private var intervalDropDown: some View {
        TangemDropDown(
            singleSelection: Binding(
                get: { RealAssetsIntervalOption(interval: viewModel.selectedInterval) },
                set: { viewModel.selectedInterval = $0.interval }
            ),
            in: viewModel.intervalOptions.map(RealAssetsIntervalOption.init)
        )
        .accessibilityIdentifier { option in
            MarketsAccessibilityIdentifiers.marketsIntervalSegment(option.interval.rawValue)
        }
        .fixedSize(horizontal: true, vertical: false)
        .id(viewModel.selectedInterval)
    }

    private var orderChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Layout.orderChipSpacing) {
                ForEach(viewModel.orderOptions) { order in
                    orderChip(order)
                }
            }
            .padding(.horizontal, Layout.contentHorizontalPadding)
        }
        .animation(.spring, value: viewModel.selectedOrder)
    }

    private func orderChip(_ order: MarketsListOrderType) -> some View {
        let isSelected = viewModel.selectedOrder == order

        return SwiftUI.Button(action: { viewModel.selectedOrder = order }) {
            Text(order.realAssetsNameLocalized)
                .style(
                    DesignSystem.Font.subheadingMediumToken,
                    color: isSelected ? DesignSystem.Color.textPrimary : DesignSystem.Color.textSecondary
                )
                .lineLimit(1)
                .padding(.horizontal, Layout.orderChipHorizontalPadding)
                .frame(minHeight: orderChipHeight)
                .contentShape(.capsule)
                .background {
                    if isSelected {
                        Capsule().fill(DesignSystem.Color.bgTransparentSecondary)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var regionRestrictionBanner: some View {
        MessageBanner(
            title: Localization.marketsRealAssetsRegionRestrictionTitle,
            description: viewModel.regionRestrictionDescription
        )
        .variant(.warning)
        .glowRing(.warning)
        .slotEnd {
            DesignSystem.Icons.Info.regular20.image
                .renderingMode(.template)
                .resizable()
                .frame(width: bannerIconSize, height: bannerIconSize)
                .foregroundStyle(DesignSystem.Color.iconPrimary)
        }
    }

    @ViewBuilder
    private var list: some View {
        switch viewModel.tokenListLoadingState {
        case .error:
            TangemUnableToLoadDataView(isButtonBusy: false, retryButtonAction: viewModel.tryLoadAgain)
                .infinityFrame(axis: .horizontal, alignment: .center)
                .padding(.vertical, Layout.stateVerticalPadding)

        case .noResults:
            Text(Localization.marketsRealAssetsEmptyTitle)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .infinityFrame(axis: .horizontal, alignment: .center)
                .padding(.vertical, Layout.stateVerticalPadding)

        case .loading, .idle, .allDataLoaded:
            LazyVStack(spacing: .zero) {
                ForEach(viewModel.tokenViewModels) { itemViewModel in
                    MarketTokenRowView(viewModel: itemViewModel.tokenItemViewModel)
                        .onAppear(perform: itemViewModel.onAppear)
                        .onDisappear(perform: itemViewModel.onDisappear)
                }

                if viewModel.tokenListLoadingState == .loading {
                    ForEach(0 ..< Layout.skeletonRowsCount, id: \.self) { _ in
                        TokenRowMarket(.shimmer)
                    }
                }
            }
        }
    }
}

private extension RealAssetsContentView {
    enum Layout {
        static let contentHorizontalPadding: CGFloat = 16
        static let contentSpacing: CGFloat = 12
        static let listCornerRadius: CGFloat = 24
        static let stateVerticalPadding: CGFloat = 64
        static let skeletonRowsCount = 5
        static let orderChipSpacing: CGFloat = 4
        static let orderChipHorizontalPadding: CGFloat = 12
    }
}

private struct RealAssetsIntervalOption: TangemDropDownTextProvider {
    let interval: MarketsPriceIntervalType

    var text: String {
        interval.realAssetsNameLocalized
    }
}

private extension MarketsPriceIntervalType {
    var realAssetsNameLocalized: String {
        switch self {
        case .day: Localization.marketsRealAssetsIntervalDay
        case .week: Localization.marketsRealAssetsIntervalWeek
        case .month: Localization.marketsRealAssetsIntervalMonth
        default: tokenDetailsNameLocalized
        }
    }
}

private extension MarketsListOrderType {
    var realAssetsNameLocalized: String {
        switch self {
        case .rating: Localization.marketsRealAssetsSortMarketCap
        case .gainers: Localization.marketsRealAssetsSortTopGainers
        case .losers: Localization.marketsRealAssetsSortTopLosers
        default: description
        }
    }
}
