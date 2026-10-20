//
//  PolymarketMyPositionsView.swift
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

struct PolymarketMyPositionsView: View {
    @ObservedObject private var viewModel: PolymarketMyPositionsViewModel

    @State private var headerHeight: CGFloat = 0

    init(viewModel: PolymarketMyPositionsViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .top) {
            content

            header
        }
        .modal(
            item: $viewModel.finishedPosition,
            header: { model in
                FeedModalHeaderView(title: model.title, onClose: { viewModel.finishedPosition = nil })
            },
            content: { model in
                PolymarketFinishedPositionSheetView(model: model)
            }
        )
        .scrollIndicators(.hidden)
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        VStack(spacing: 0) {
            PolymarketTopBar(
                title: Localization.predictionPositionsTitle,
                onBack: { viewModel.handleViewAction(.close) }
            )
            .padding(.top, Constants.topBarTopPadding)

            controlsRow
                .padding(.horizontal, Constants.horizontalPadding)
                .padding(.top, Constants.contentTopPadding)
        }
        .padding(.bottom, Constants.blockSpacing)
        .readGeometry(\.size.height, bindTo: $headerHeight)
        .background {
            Fade(position: .top)
                .blurred()
                .backgroundColor(DesignSystem.Color.bgPrimary)
                .ignoresSafeArea(edges: .top)
        }
    }

    private var content: some View {
        GroupedScrollView(contentType: .lazy(spacing: Constants.blockSpacing)) {
            listSection
        }
        .horizontalPadding(Constants.horizontalPadding)
        .safeAreaInset(edge: .top, spacing: 0) {
            Color.clear.frame(height: headerHeight)
        }
        .refreshable { await viewModel.refresh() }
    }

    private var controlsRow: some View {
        HStack(spacing: Constants.controlsSpacing) {
            TabNavigation(data: viewModel.tabs, selection: $viewModel.tab)

            Spacer(minLength: Constants.controlsSpacing)

            filterChip
        }
        .padding(.bottom, Constants.controlsBottomPadding)
    }

    private var filterChip: some View {
        Menu {
            filterPicker
        } label: {
            filterItem
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var filterItem: some View {
        if viewModel.filter == .all {
            // [REDACTED_TODO_COMMENT]
            FilterItem(.inactive(label: "Types"), action: {})
                .accessibilityLabel("Types")
        } else {
            FilterItem(.active(value: viewModel.filter.title), action: {})
                .accessibilityLabel(viewModel.filter.title)
        }
    }

    private var filterPicker: some View {
        Picker(
            selection: Binding(
                get: { viewModel.filter },
                set: { viewModel.handleViewAction(.selectFilter($0)) }
            )
        ) {
            ForEach(viewModel.filters) { filter in
                Text(filter.title).tag(filter)
            }
        } label: {
            EmptyView()
        }
    }

    private var listSection: some View {
        listContent
            .polymarketStateTransition(contentState)
    }

    @ViewBuilder
    private var listContent: some View {
        switch viewModel.loadingState {
        case .loading:
            PolymarketPositionsSkeletonView(rowCount: Constants.skeletonRowCount)
        case .error:
            PolymarketEmptyMessageView(
                message: Localization.predictionPositionsLoadError,
                onRetry: { viewModel.handleViewAction(.retry) }
            )
        case .empty:
            emptyState
        case .allDataLoaded where viewModel.rows.isEmpty:
            emptyState
        default:
            LazyVStack(spacing: Constants.blockSpacing) {
                rows

                paginationFooter
            }
        }
    }

    private var contentState: PolymarketMyPositionsViewModel.LoadingState {
        switch viewModel.loadingState {
        case .loading, .error, .empty: viewModel.loadingState
        case .allDataLoaded where viewModel.rows.isEmpty: .empty
        case .loaded, .allDataLoaded, .paginationLoading, .paginationError: .loaded
        }
    }

    private var rows: some View {
        ForEach(viewModel.rows) { model in
            PolymarketPositionRow(model: model) { viewModel.handleViewAction(.openPositionDetails(id: model.id)) }
                .onAppear { viewModel.handleViewAction(.onRowVisibilityChange(id: model.id, isVisible: true)) }
                .onDisappear { viewModel.handleViewAction(.onRowVisibilityChange(id: model.id, isVisible: false)) }
        }
    }

    private var emptyState: some View {
        Text(viewModel.emptyMessage)
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
            .frame(maxWidth: .infinity, minHeight: Constants.emptyMinHeight)
    }

    private var paginationFooter: some View {
        paginationFooterContent
            .animation(.default, value: viewModel.loadingState == .paginationError)
    }

    @ViewBuilder
    private var paginationFooterContent: some View {
        switch viewModel.loadingState {
        case .loaded:
            Color.clear
                .frame(height: Constants.paginationTriggerHeight)
                .onAppear { viewModel.handleViewAction(.loadNextPage) }
        case .paginationLoading:
            Loader()
                .frame(maxWidth: .infinity)
                .padding(.vertical, Constants.paginationVerticalPadding)
        case .paginationError:
            TangemUnableToLoadDataView(
                isButtonBusy: false,
                retryButtonAction: { viewModel.handleViewAction(.retryNextPage) }
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, Constants.paginationVerticalPadding)
        case .loading, .error, .empty, .allDataLoaded:
            EmptyView()
        }
    }
}

// MARK: - Constants

private extension PolymarketMyPositionsView {
    enum Constants {
        static let topBarTopPadding: CGFloat = 8
        static let horizontalPadding: CGFloat = 16
        static let contentTopPadding: CGFloat = 8
        static let blockSpacing: CGFloat = 8
        static let controlsSpacing: CGFloat = 8
        static let controlsBottomPadding: CGFloat = 8
        static let emptyMinHeight: CGFloat = 160
        static let paginationTriggerHeight: CGFloat = 1
        static let paginationVerticalPadding: CGFloat = 16
        static let skeletonRowCount = 6
    }
}
