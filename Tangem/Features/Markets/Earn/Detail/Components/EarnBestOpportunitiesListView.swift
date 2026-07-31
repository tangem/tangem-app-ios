//
//  EarnBestOpportunitiesListView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemUI
import TangemUIUtils
import TangemLocalization

struct EarnBestOpportunitiesListView: View {
    let loadingState: LoadingState
    let tokenViewModels: [EarnTokenItemViewModel]
    let retryAction: () -> Void
    let fetchMoreAction: () -> Void
    let hasActiveFilters: Bool
    let clearFilterAction: (() -> Void)?

    private var backgroundColor: Color {
        DesignSystem.Color.bgSecondary
    }

    var body: some View {
        rootView
            .defaultRoundedBackground(
                with: backgroundColor,
                verticalPadding: Layout.innerContentPadding,
                horizontalPadding: Layout.innerContentPadding,
                cornerRadius: 24
            )
            .padding(.horizontal, Layout.horizontalPadding)
    }

    @ViewBuilder
    private var rootView: some View {
        switch loadingState {
        case .loading:
            loadingSkeletons
        case .idle, .allDataLoaded:
            opportunitiesList
        case .noResults:
            emptyView
        case .error:
            errorView
        }
    }

    private var loadingSkeletons: some View {
        loadingSkeletonsRedesign
    }

    private var loadingSkeletonsRedesign: some View {
        VStack(spacing: .zero) {
            ForEach(0 ..< 8) { _ in
                TangemTwoLineRowSkeletonView()
            }
        }
    }

    private var opportunitiesList: some View {
        LazyVStack(spacing: Layout.itemSpacing) {
            ForEach(tokenViewModels) { viewModel in
                EarnTokenItemViewRedesign(viewModel: viewModel)
            }

            paginationFooter
        }
        .transition(.opacity.animation(.easeInOut))
    }

    @ViewBuilder
    private var paginationFooter: some View {
        switch loadingState {
        case .idle:
            Color.clear
                .frame(height: 1)
                .onAppear {
                    fetchMoreAction()
                }
        case .allDataLoaded, .loading, .noResults, .error:
            EmptyView()
        }
    }

    @ViewBuilder
    private var emptyView: some View {
        if hasActiveFilters {
            emptyViewWithClearFilter
        } else {
            emptyViewWithoutFilters
        }
    }

    private var emptyViewWithoutFilters: some View {
        VStack(spacing: Layout.emptyViewSpacing) {
            Assets.emptyTokenList.image
                .foregroundColor(DesignSystem.Color.iconTertiary)

            Text(Localization.earnEmpty)
                .multilineTextAlignment(.center)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Layout.emptyViewHorizontalPadding)
        .infinityFrame(axis: .horizontal, alignment: .center)
        .frame(height: Layout.defaultMaxHeight)
    }

    private var emptyViewWithClearFilter: some View {
        VStack(spacing: Layout.emptyViewSpacing) {
            Text(Localization.earnNoResults)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)

            if let clearFilterAction {
                TangemUI.Button(
                    label: AttributedString(Localization.earnClearFilter),
                    accessibilityLabel: Localization.earnClearFilter,
                    action: clearFilterAction
                )
                .size(.x9)
                .styleType(.secondary)
            }
        }
        .infinityFrame(axis: .horizontal, alignment: .center)
        .frame(height: Layout.defaultMaxHeight)
    }

    private var errorView: some View {
        Group {
            TangemUnableToLoadDataView(
                isButtonBusy: false,
                retryButtonAction: retryAction
            )
        }
        .infinityFrame(axis: .horizontal, alignment: .center)
        .frame(height: Layout.defaultMaxHeight)
    }
}

// MARK: - Layout

private extension EarnBestOpportunitiesListView {
    enum Layout {
        static let itemSpacing: CGFloat = .zero
        static let horizontalPadding: CGFloat = 16.0
        static let innerContentPadding: CGFloat = 0.0
        static let defaultMaxHeight: CGFloat = 180
        static let emptyViewSpacing: CGFloat = 16
        static let emptyViewHorizontalPadding: CGFloat = 48
    }
}

// MARK: - LoadingState

extension EarnBestOpportunitiesListView {
    enum LoadingState {
        case loading
        case idle
        case noResults
        case allDataLoaded
        case error
    }
}
