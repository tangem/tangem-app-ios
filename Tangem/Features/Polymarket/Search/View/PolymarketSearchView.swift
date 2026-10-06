//
//  PolymarketSearchView.swift
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
import TangemUIUtils

struct PolymarketSearchView: View {
    @ObservedObject var viewModel: PolymarketSearchViewModel

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .prompt:
            placeholder(
                icon: Assets.DesignSystem.search,
                title: Localization.predictionSearchInitialTitle,
                subtitle: Localization.predictionSearchInitialSubtitle
            )
        case .loading:
            skeleton
        case .noResults:
            placeholder(
                icon: Assets.DesignSystem.search,
                title: Localization.predictionSearchEmptyTitle,
                subtitle: Localization.predictionSearchEmptySubtitle
            )
        case .error:
            PolymarketEmptyMessageView(message: Localization.predictionMainEventsLoadError, onRetry: { viewModel.handleViewAction(.retry) })
                .frame(maxHeight: .infinity)
        case .loaded, .allDataLoaded, .paginationLoading, .paginationError:
            results
        }
    }

    private var skeleton: some View {
        ScrollView {
            LazyVStack(spacing: Constants.contentSpacing) {
                PolymarketEventsSkeletonView()
            }
            .padding(.vertical, Constants.contentVerticalPadding)
        }
        .scrollDisabled(true)
    }

    private var results: some View {
        ScrollView {
            LazyVStack(spacing: Constants.contentSpacing) {
                resultsTitle

                eventCards

                paginationFooter
            }
            .padding(.vertical, Constants.contentVerticalPadding)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.immediately)
    }

    private var resultsTitle: some View {
        Text(Localization.predictionSearchResultsTitle)
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Constants.horizontalPadding)
    }

    private var eventCards: some View {
        ForEach(viewModel.eventCards, id: \.id) { model in
            PolymarketEventCard(model: model)
                .contentShape(.rect)
                .onTapGesture { viewModel.handleViewAction(.openEventDetails(id: model.id)) }
                .padding(.horizontal, Constants.horizontalPadding)
        }
    }

    // MARK: - Pagination

    @ViewBuilder
    private var paginationFooter: some View {
        switch viewModel.state {
        case .loaded:
            paginationLoader
                .onAppear { viewModel.handleViewAction(.loadNextPage) }
        case .paginationLoading:
            paginationLoader
        case .paginationError:
            TangemUnableToLoadDataView(isButtonBusy: false, retryButtonAction: { viewModel.handleViewAction(.retryNextPage) })
                .frame(maxWidth: .infinity)
                .padding(.vertical, Constants.paginationVerticalPadding)
        case .prompt, .loading, .noResults, .error, .allDataLoaded:
            EmptyView()
        }
    }

    private var paginationLoader: some View {
        Loader()
            .frame(maxWidth: .infinity)
            .padding(.vertical, Constants.paginationVerticalPadding)
    }

    // MARK: - Placeholder

    private func placeholder(icon: ImageType, title: String, subtitle: String) -> some View {
        VStack(spacing: Constants.placeholderSpacing) {
            icon.image
                .renderingMode(.template)
                .resizable()
                .foregroundStyle(DesignSystem.Color.iconTertiary)
                .frame(width: Constants.placeholderIconSide, height: Constants.placeholderIconSide)

            VStack(spacing: Constants.placeholderTextSpacing) {
                Text(title)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)

                Text(subtitle)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            }
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Constants.placeholderHorizontalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Constants

private extension PolymarketSearchView {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let contentSpacing: CGFloat = 12
        static let contentVerticalPadding: CGFloat = 12
        static let paginationVerticalPadding: CGFloat = 16
        static let placeholderSpacing: CGFloat = 16
        static let placeholderTextSpacing: CGFloat = 2
        static let placeholderIconSide: CGFloat = 40
        static let placeholderHorizontalPadding: CGFloat = 32
    }
}
