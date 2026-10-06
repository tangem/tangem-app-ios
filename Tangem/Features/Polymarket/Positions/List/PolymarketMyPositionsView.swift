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

    init(viewModel: PolymarketMyPositionsViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            PolymarketTopBar(
                title: Localization.predictionPositionsTitle,
                onBack: { viewModel.handleViewAction(.close) }
            )
            .padding(.top, Constants.topBarTopPadding)

            content
        }
        .sheet(item: $viewModel.finishedPosition) { model in
            PolymarketFinishedPositionSheetView(model: model)
                .presentationDetents(idealHeight: Constants.finishedPositionSheetHeight)
                .presentationBackground(DesignSystem.Color.bgPrimary)
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var content: some View {
        GroupedScrollView(contentType: .lazy(spacing: Constants.blockSpacing)) {
            controlsRow

            listSection
        }
        .horizontalPadding(Constants.horizontalPadding)
        .padding(.top, Constants.contentTopPadding)
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

    @ViewBuilder
    private var listSection: some View {
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
            rows

            paginationFooter
        }
    }

    private var rows: some View {
        ForEach(viewModel.rows) { model in
            PolymarketPositionRow(model: model) { viewModel.handleViewAction(.openPositionDetails(id: model.id)) }
        }
    }

    private var emptyState: some View {
        Text(viewModel.emptyMessage)
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
            .frame(maxWidth: .infinity, minHeight: Constants.emptyMinHeight)
    }

    @ViewBuilder
    private var paginationFooter: some View {
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
        static let finishedPositionSheetHeight: CGFloat = 420
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
