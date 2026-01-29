//
//  EarnDetailView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemLocalization

struct EarnDetailView: View {
    @ObservedObject var viewModel: EarnDetailViewModel

    var body: some View {
        VStack(spacing: .zero) {
            header

            contentView
        }
        .background(Color.Tangem.Surface.level3.ignoresSafeArea())
    }

    private var header: some View {
        NavigationBar(
            title: Localization.earnTitle,
            leftButtons: {
                BackButton(
                    height: 44.0,
                    isVisible: true,
                    isEnabled: true,
                    hPadding: 10.0,
                    action: { viewModel.handleViewAction(.back) }
                )
            }
        )
        .padding(.top, 12)
    }

    private var contentView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                mostlyUsedSection

                bestOpportunitiesSection
            }
        }
    }

    @ViewBuilder
    private var mostlyUsedSection: some View {
        if !viewModel.mostlyUsedViewModels.isEmpty {
            EarnDetailHeaderView(headerTitle: Localization.earnMostlyUsed)

            EarnMostlyUsedView(viewModels: viewModel.mostlyUsedViewModels)
        }
    }

    private var bestOpportunitiesSection: some View {
        VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
            EarnDetailHeaderView(headerTitle: Localization.earnBestOpportunities)

            EarnFilterHeaderView(
                networkFilterTitle: viewModel.currentNetworkFilter.displayTitle,
                typesFilterTitle: viewModel.currentFilterType.description,
                onNetworksTap: { viewModel.handleViewAction(.networksFilterTap) },
                onTypesTap: { viewModel.handleViewAction(.typesFilterTap) }
            )
            bestOpportunitiesContent
        }
    }

    @ViewBuilder
    private var bestOpportunitiesContent: some View {
        switch viewModel.bestOpportunitiesResultState {
        case .loading:
            loadingSkeletons
        case .success(let viewModels):
            opportunitiesList(viewModels: viewModels)
        case .failure:
            errorView
        }
    }

    private var loadingSkeletons: some View {
        VStack(spacing: .zero) {
            ForEach(0 ..< 5) { _ in
                MarketsSkeletonItemView()
            }
        }
        .padding(.horizontal, Layout.horizontalPadding)
    }

    private func opportunitiesList(viewModels: [EarnTokenItemViewModel]) -> some View {
        EarnBestOpportunitiesListView(viewModels: viewModels)
    }

    private var errorView: some View {
        UnableToLoadDataView(
            isButtonBusy: false,
            retryButtonAction: { viewModel.retryBestOpportunities() }
        )
        .padding(.horizontal, Layout.horizontalPadding)
    }
}

private extension EarnDetailView {
    enum Layout {
        static let sectionSpacing: CGFloat = 12.0
        static let horizontalPadding: CGFloat = 16.0
    }
}
