//
//  EarnContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUIUtils

struct EarnContentView: View {
    @ObservedObject var viewModel: EarnDetailViewModel

    @ScaledMetric private var sectionsSpacing: CGFloat = 48
    @ScaledMetric private var featuredHeaderSpacing: CGFloat = 16
    @ScaledMetric private var listHeaderSpacing: CGFloat = 12
    @ScaledMetric private var filtersSpacing: CGFloat = 16

    var body: some View {
        VStack(spacing: sectionsSpacing) {
            mostlyUsedSection
            bestOpportunitiesSection
        }
        .onFirstAppear(perform: viewModel.onFirstAppear)
    }
}

// MARK: - Subviews

private extension EarnContentView {
    @ViewBuilder
    var mostlyUsedSection: some View {
        if viewModel.isMostlyUsedSectionVisible {
            VStack(spacing: featuredHeaderSpacing) {
                EarnDetailHeaderView(headerTitle: Localization.commonFeatured)

                EarnMostlyUsedView(
                    viewModels: viewModel.mostlyUsedViewModels,
                    retryAction: viewModel.onMostlyUsedRetry,
                    onFourthItemAppeared: viewModel.onMostlyUsedScrolledToFourthItem
                )
            }
        }
    }

    var bestOpportunitiesSection: some View {
        VStack(spacing: .zero) {
            EarnDetailHeaderView(headerTitle: Localization.earnAssets)
                .padding(.bottom, listHeaderSpacing)

            EarnFilterHeaderView(
                isNetworksFilterEnabled: viewModel.isFilterInteractionEnabled,
                isTypesFilterEnabled: true,
                isLoading: viewModel.isFilterLoading,
                networkFilterTitle: viewModel.selectedNetworkFilterTitle,
                typesFilterTitle: viewModel.selectedFilterTypeTitle,
                onNetworksTap: { viewModel.handleViewAction(.networksFilterTap) },
                onTypesTap: { viewModel.handleViewAction(.typesFilterTap) }
            )
            .padding(.bottom, filtersSpacing)

            EarnBestOpportunitiesListView(
                loadingState: viewModel.listLoadingState,
                tokenViewModels: viewModel.tokenViewModels,
                retryAction: viewModel.onRetry,
                fetchMoreAction: viewModel.fetchMore,
                hasActiveFilters: viewModel.hasActiveFilters,
                clearFilterAction: viewModel.clearFilters
            )
        }
    }
}
