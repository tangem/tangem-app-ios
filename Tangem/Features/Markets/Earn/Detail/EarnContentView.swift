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

    @ScaledMetric private var sectionsSpacing: CGFloat = 40
    @ScaledMetric private var sectionSpacing: CGFloat = 12

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
            VStack(spacing: sectionSpacing) {
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
        VStack(spacing: sectionSpacing) {
            EarnDetailHeaderView(headerTitle: Localization.earnBestOpportunities)

            EarnFilterHeaderView(
                isNetworksFilterEnabled: viewModel.isFilterInteractionEnabled,
                isTypesFilterEnabled: true,
                isLoading: viewModel.isFilterLoading,
                networkFilterTitle: viewModel.selectedNetworkFilterTitle,
                typesFilterTitle: viewModel.selectedFilterTypeTitle,
                onNetworksTap: { viewModel.handleViewAction(.networksFilterTap) },
                onTypesTap: { viewModel.handleViewAction(.typesFilterTap) }
            )

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
