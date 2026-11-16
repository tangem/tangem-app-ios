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

    var isPlaceholder = false

    var body: some View {
        content
            .polymarketStateTransition(ContentIdentity(feed: contentState == .loaded ? viewModel.feedKey : nil, state: contentState))
    }

    @ViewBuilder
    private var content: some View {
        switch displayedState {
        case .loading:
            VStack(spacing: Constants.cardSpacing) {
                PolymarketEventsSkeletonView()
            }
        case .error:
            PolymarketEmptyMessageView(message: Localization.predictionMainEventsLoadError, onRetry: { viewModel.handleViewAction(.retry) })
        case .noResults:
            noResultsState
        case .loaded, .allDataLoaded, .paginationLoading, .paginationError:
            LazyVStack(spacing: Constants.cardSpacing) {
                eventCards

                paginationFooter
            }
        }
    }
}

// MARK: - Animation

private extension PolymarketEventsListView {
    struct ContentIdentity: Hashable {
        let feed: PolymarketEventsBlockViewModel.FeedKey?
        let state: PolymarketEventsBlockViewModel.LoadingState
    }

    var displayedState: PolymarketEventsBlockViewModel.LoadingState {
        isPlaceholder ? .loading : viewModel.loadingState
    }

    var contentState: PolymarketEventsBlockViewModel.LoadingState {
        switch displayedState {
        case .loading, .error, .noResults: displayedState
        case .loaded, .allDataLoaded, .paginationLoading, .paginationError: .loaded
        }
    }
}

// MARK: - Subviews

private extension PolymarketEventsListView {
    var eventCards: some View {
        ForEach(viewModel.eventCards) { card in
            PolymarketFeedCardView(card: card)
                .contentShape(.rect)
                .onTapGesture { viewModel.handleViewAction(.openEventDetails(id: card.id)) }
                .padding(.horizontal, PolymarketMainLayout.horizontalPadding)
                .onAppear { viewModel.handleViewAction(.onEventVisibilityChange(id: card.id, isVisible: true)) }
                .onDisappear { viewModel.handleViewAction(.onEventVisibilityChange(id: card.id, isVisible: false)) }
        }
    }

    var noResultsState: some View {
        Text(Localization.predictionMainEmptyEvents)
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
            .frame(maxWidth: .infinity, minHeight: Constants.placeholderMinHeight)
    }

    var paginationFooter: some View {
        paginationFooterContent
            .animation(.default, value: viewModel.loadingState == .paginationError)
    }

    @ViewBuilder
    var paginationFooterContent: some View {
        switch viewModel.loadingState {
        case .loaded:
            paginationLoader
                .onAppear { viewModel.handleViewAction(.loadNextPage) }
        case .paginationLoading:
            paginationLoader
        case .paginationError:
            UnableToLoadDataView(isButtonBusy: false, retryButtonAction: { viewModel.handleViewAction(.retryNextPage) })
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
        static let cardSpacing: CGFloat = 12
        static let placeholderMinHeight: CGFloat = 320
    }
}
