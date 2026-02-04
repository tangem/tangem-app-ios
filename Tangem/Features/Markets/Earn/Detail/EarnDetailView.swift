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
        .onAppear {
            viewModel.onAppear()
        }
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

            ZStack(alignment: .center) {
                EarnFilterHeaderView(
                    networkFilterTitle: viewModel.selectedNetworkFilterTitle,
                    typesFilterTitle: viewModel.selectedFilterTypeTitle,
                    onNetworksTap: { viewModel.handleViewAction(.networksFilterTap) },
                    onTypesTap: { viewModel.handleViewAction(.typesFilterTap) }
                )
//                .disabled(!viewModel.isFilterInteractionEnabled)

                if viewModel.isFilterLoading {
                    ProgressView()
                }
            }

            EarnBestOpportunitiesListView(
                loadingState: viewModel.listLoadingState,
                tokenViewModels: viewModel.tokenViewModels,
                retryAction: viewModel.onRetry
            )
            .defaultRoundedBackground(
                with: Color.Tangem.Surface.level4,
                verticalPadding: Layout.innerContentPadding,
                horizontalPadding: Layout.innerContentPadding
            )
        }
    }
}

private extension EarnDetailView {
    enum Layout {
        static let sectionSpacing: CGFloat = 12.0
        static let horizontalPadding: CGFloat = 16.0
        static let innerContentPadding: CGFloat = 0.0
    }
}
