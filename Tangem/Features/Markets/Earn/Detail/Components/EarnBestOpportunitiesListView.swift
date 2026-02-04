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
    let hasActiveFilters: Bool
    let clearFilterAction: (() -> Void)?

    var body: some View {
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
        VStack(spacing: .zero) {
            ForEach(0 ..< 5) { _ in
                MarketsSkeletonItemView()
            }
        }
        .padding(.horizontal, Layout.horizontalPadding)
    }

    private var opportunitiesList: some View {
        LazyVStack(spacing: Layout.itemSpacing) {
            ForEach(tokenViewModels) { viewModel in
                EarnTokenItemView(viewModel: viewModel)
            }
        }
        .padding(.horizontal, Layout.horizontalPadding)
    }

    private var emptyView: some View {
        VStack(spacing: Layout.emptyViewSpacing) {
            Text(Localization.earnNoResults)
                .foregroundColor(Colors.Text.tertiary)

            if hasActiveFilters, let clearFilterAction {
                Button(action: clearFilterAction) {
                    Text(Localization.earnClearFilter)
                        .style(Fonts.Bold.caption1.weight(.medium), color: Colors.Text.primary1)
                }
                .roundedBackground(with: Colors.Button.secondary, verticalPadding: 6, horizontalPadding: 12, radius: 10)
            }
        }
        .padding()
    }

    private var errorView: some View {
        UnableToLoadDataView(
            isButtonBusy: false,
            retryButtonAction: retryAction
        )
        .infinityFrame(axis: .horizontal, alignment: .center)
        .frame(maxHeight: Layout.defaultMaxHeight)
        .defaultRoundedBackground(
            with: Colors.Background.action,
            verticalPadding: Layout.verticalPadding,
            horizontalPadding: Layout.horizontalPadding
        )
        .padding(.horizontal, Layout.horizontalPadding)
    }
}

// MARK: - Layout

private extension EarnBestOpportunitiesListView {
    enum Layout {
        static let itemSpacing: CGFloat = .zero
        static let horizontalPadding: CGFloat = 16.0
        static let verticalPadding: CGFloat = 34
        static let defaultMaxHeight: CGFloat = 130
        static let emptyViewSpacing: CGFloat = 12
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
