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
        isRedesignEnabled ? .Tangem.Surface.level3 : Colors.Background.action
    }

    private var isRedesignEnabled: Bool {
        FeatureProvider.isAvailable(.redesign)
    }

    var body: some View {
        rootView
            .defaultRoundedBackground(
                with: backgroundColor,
                verticalPadding: Layout.innerContentPadding,
                horizontalPadding: Layout.innerContentPadding,
                cornerRadius: isRedesignEnabled ? .unit(.x6) : Self.defaultCornerRadius
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

    @ViewBuilder
    private var loadingSkeletons: some View {
        if isRedesignEnabled {
            loadingSkeletonsRedesign
        } else {
            loadingSkeletonsLegacy
        }
    }

    private var loadingSkeletonsRedesign: some View {
        VStack(spacing: .zero) {
            ForEach(0 ..< 8) { _ in
                TangemTwoLineRowSkeletonView()
            }
        }
    }

    private var loadingSkeletonsLegacy: some View {
        VStack(spacing: .zero) {
            ForEach(0 ..< 5) { _ in
                MarketsSkeletonItemView()
            }
        }
    }

    private var opportunitiesList: some View {
        LazyVStack(spacing: Layout.itemSpacing) {
            ForEach(tokenViewModels) { viewModel in
                if FeatureProvider.isAvailable(.redesign) {
                    EarnTokenItemViewRedesign(viewModel: viewModel)
                } else {
                    EarnTokenItemView(viewModel: viewModel)
                }
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
                .foregroundColor(Colors.Icon.inactive)

            Text(Localization.earnEmpty)
                .multilineTextAlignment(.center)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Layout.emptyViewHorizontalPadding)
        .infinityFrame(axis: .horizontal, alignment: .center)
        .frame(height: Layout.defaultMaxHeight)
    }

    private var emptyViewWithClearFilter: some View {
        VStack(spacing: Layout.emptyViewSpacing) {
            if isRedesignEnabled {
                Text(Localization.earnNoResults)
                    .style(Font.Tangem.Body14.regular, color: .Tangem.Text.Neutral.tertiary)
            } else {
                Text(Localization.earnNoResults)
                    .style(Fonts.Bold.caption1, color: Colors.Text.tertiary)
            }

            if let clearFilterAction {
                Button(action: clearFilterAction) {
                    Text(Localization.earnClearFilter)
                        .style(
                            isRedesignEnabled ? Font.Tangem.Body16.semibold : TangemFontStyle(font: Fonts.Bold.caption1),
                            color: isRedesignEnabled ? .Tangem.Text.Neutral.primary : Colors.Text.primary1
                        )
                }
                .roundedBackground(
                    with: Colors.Button.secondary,
                    verticalPadding: Layout.ClearFilterButton.verticalPadding,
                    horizontalPadding: Layout.ClearFilterButton.horizontalPadding,
                    radius: Layout.ClearFilterButton.radius
                )
            }
        }
        .infinityFrame(axis: .horizontal, alignment: .center)
        .frame(height: Layout.defaultMaxHeight)
    }

    private var errorView: some View {
        Group {
            if isRedesignEnabled {
                TangemUnableToLoadDataView(
                    isButtonBusy: false,
                    retryButtonAction: retryAction
                )
            } else {
                UnableToLoadDataView(
                    isButtonBusy: false,
                    retryButtonAction: retryAction
                )
            }
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

        enum ClearFilterButton {
            static let verticalPadding: CGFloat = 8
            static let horizontalPadding: CGFloat = 12
            static let radius: CGFloat = 100
        }
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
