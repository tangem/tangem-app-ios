//
//  PolymarketEventsListView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemPolymarketUI
import TangemUI

struct PolymarketEventsListView: View {
    @ObservedObject var viewModel: PolymarketEventsBlockViewModel

    var body: some View {
        switch viewModel.loadingState {
        case .loading:
            PolymarketEventsSkeletonView()
        case .error:
            PolymarketEmptyMessageView(message: Localization.predictionMainEventsLoadError, onRetry: { viewModel.handleViewAction(.retry) })
        case .noResults:
            noResultsState
        case .loaded, .allDataLoaded, .paginationLoading, .paginationError:
            eventCards

            paginationFooter
        }
    }
}

// MARK: - Subviews

private extension PolymarketEventsListView {
    var eventCards: some View {
        ForEach(viewModel.eventCards, id: \.id) { model in
            PolymarketEventCard(model: model)
                .contentShape(.rect)
                .onTapGesture { viewModel.handleViewAction(.openEventDetails(id: model.id)) }
                .padding(.horizontal, PolymarketMainLayout.horizontalPadding)
        }
    }

    var noResultsState: some View {
        Text(Localization.predictionMainEmptyEvents)
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
            .frame(maxWidth: .infinity, minHeight: Constants.placeholderMinHeight)
    }

    @ViewBuilder
    var paginationFooter: some View {
        switch viewModel.loadingState {
        case .loaded:
            paginationLoader
                .onAppear { viewModel.handleViewAction(.loadNextPage) }
        case .paginationLoading:
            paginationLoader
        case .paginationError:
            TangemUnableToLoadDataView(isButtonBusy: false, retryButtonAction: { viewModel.handleViewAction(.retryNextPage) })
                .frame(maxWidth: .infinity)
                .padding(.vertical, Constants.paginationVerticalPadding)
        case .loading, .error, .noResults, .allDataLoaded:
            EmptyView()
        }
    }

    var paginationLoader: some View {
        Loader()
            .frame(maxWidth: .infinity)
            .padding(.vertical, Constants.paginationVerticalPadding)
    }
}

// MARK: - Constants

private extension PolymarketEventsListView {
    enum Constants {
        static let paginationVerticalPadding: CGFloat = 20
        static let placeholderMinHeight: CGFloat = 320
    }
}
