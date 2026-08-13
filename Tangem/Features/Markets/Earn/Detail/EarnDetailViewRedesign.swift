//
//  EarnDetailViewRedesign.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets
import TangemLocalization

struct EarnDetailViewRedesign: View {
    @ObservedObject var viewModel: EarnDetailViewModel

    @Injected(\.overlayContentStateObserver) private var overlayContentStateObserver: OverlayContentStateObserver

    @ScaledMetric private var contentSpacing: CGFloat = 16
    @ScaledMetric private var sectionsSpacing: CGFloat = 40
    @ScaledMetric private var sectionSpacing: CGFloat = 12

    var body: some View {
        content
            .onOverlayContentProgressChange(overlayContentStateObserver: overlayContentStateObserver) { [weak viewModel] progress in
                viewModel?.onOverlayContentProgressChange(progress)
            }
            .onFirstAppear(perform: viewModel.onFirstAppear)
    }
}

// MARK: - Subviews

private extension EarnDetailViewRedesign {
    var content: some View {
        scrollContent
            .background(DesignSystem.Color.bgPrimary)
            .safeAreaInset(edge: .top, spacing: contentSpacing) {
                navigationBar
            }
    }

    var scrollContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: sectionsSpacing) {
                mostlyUsedSection
                bestOpportunitiesSection
            }
        }
        .opacity(viewModel.overlayContentHidingProgress)
    }

    var mostlyUsedSection: some View {
        VStack(spacing: sectionSpacing) {
            EarnDetailHeaderView(headerTitle: Localization.earnMostlyUsed)

            EarnMostlyUsedView(
                viewModels: viewModel.mostlyUsedViewModels,
                onFourthItemAppeared: viewModel.onMostlyUsedScrolledToFourthItem
            )
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

    var navigationBar: some View {
        NavigationHeader(
            leadingContent: { navigationBarLeadingButton },
            principalContent: { navigationTitle },
            trailingContent: { EmptyView() }
        )
    }

    @ViewBuilder
    var navigationBarLeadingButton: some View {
        switch viewModel.presentSource {
        case .navigation:
            NavigationBarButton.back(action: {
                viewModel.handleViewAction(.back)
            })
            .redesigned()
        case .deeplink:
            NavigationBarButton.close(action: {
                viewModel.handleViewAction(.back)
            })
            .redesigned()
        }
    }

    var navigationTitle: some View {
        Text(Localization.earnTitle)
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
    }
}
