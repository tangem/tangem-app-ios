//
//  PolymarketActivityView.swift
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

struct PolymarketActivityView: View {
    @ObservedObject private var viewModel: PolymarketActivityViewModel

    init(viewModel: PolymarketActivityViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    @State private var headerHeight: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            content

            header
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        VStack(spacing: 0) {
            PolymarketTopBar(
                title: Localization.predictionHistoryTitle,
                onBack: { viewModel.handleViewAction(.closeTapped) },
                trailing: { moreMenu }
            )
            .padding(.top, Constants.topBarTopPadding)

            tabs
        }
        .padding(.bottom, Constants.headerBottomPadding)
        .readGeometry(\.size.height, bindTo: $headerHeight)
        .background {
            Fade(position: .top)
                .blurred()
                .backgroundColor(DesignSystem.Color.bgPrimary)
                .ignoresSafeArea(edges: .top)
        }
    }

    private var tabs: some View {
        VStack(spacing: 0) {
            if viewModel.showsTabs {
                TabNavigation(data: viewModel.tabs, selection: $viewModel.tab)
                    .scrollable()
                    .padding(.top, Constants.tabsTopPadding)
                    .transition(.polymarketState)
            }
        }
        .animation(.polymarketStateChange, value: viewModel.showsTabs)
    }

    private var content: some View {
        GeometryReader { proxy in
            ScrollView {
                listContent(viewportHeight: max(proxy.size.height - headerHeight, 0))
                    .polymarketStateTransition(contentPhase)
                    .id(viewModel.tab)
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                Color.clear.frame(height: headerHeight)
            }
            .refreshable { await viewModel.refresh() }
        }
    }

    @ViewBuilder
    private func listContent(viewportHeight: CGFloat) -> some View {
        switch viewModel.loadingState {
        case .loading:
            PolymarketActivitySkeletonView(rowCount: Constants.skeletonRowCount)
        case .error(let failure):
            errorState(failure)
                .frame(minHeight: viewportHeight)
        case .noResults:
            emptyState
                .frame(minHeight: viewportHeight)
        default:
            LazyVStack(spacing: 0) {
                sections

                paginationFooter
            }
        }
    }

    private var contentPhase: String {
        switch viewModel.loadingState {
        case .loading: "loading"
        case .error: "error"
        case .noResults: "noResults"
        case .loaded, .allDataLoaded, .paginationLoading, .paginationError: "loaded"
        }
    }

    @ViewBuilder
    private func errorState(_ failure: PolymarketActivityFailure) -> some View {
        switch failure {
        case .transient:
            PolymarketEmptyMessageView(
                message: Localization.commonSomethingWentWrong,
                onRetry: { viewModel.handleViewAction(.retry) }
            )
        case .rejected:
            PolymarketPlaceholderView(
                icon: DesignSystem.Icons.Info.regular20,
                message: Localization.commonSomethingWentWrong,
                action: .init(
                    title: Localization.commonRetry,
                    icon: nil,
                    handler: { viewModel.handleViewAction(.retry) }
                )
            )
        }
    }

    private var moreMenu: some View {
        ZStack {
            if viewModel.canExport {
                Menu {
                    SwiftUI.Button(action: { viewModel.handleViewAction(.downloadCSVTapped) }) {
                        Label(
                            title: { Text(Localization.predictionHistoryDownloadCsv) },
                            icon: { DesignSystem.Icons.ArrowDownload.regular20.image.renderingMode(.template) }
                        )
                    }
                    .disabled(viewModel.isExporting)
                } label: {
                    NavigationBarButton.details {}
                        .allowsHitTesting(false)
                }
                .accessibilityLabel(Localization.commonMore)
                .transition(.polymarketState)
            }
        }
        .animation(.polymarketStateChange, value: viewModel.canExport)
    }

    private var sections: some View {
        ForEach(viewModel.sections) { section in
            PolymarketActivitySectionHeader(title: section.title)

            ForEach(section.rows) { row in
                PolymarketActivityRow(model: row, onTap: { viewModel.handleViewAction(.rowTapped(id: row.id)) })
            }
        }
    }

    private var emptyState: some View {
        PolymarketPlaceholderView(
            icon: DesignSystem.Icons.Info.regular20,
            message: viewModel.emptyMessage,
            action: viewModel.offersExploring ? exploreAction : nil
        )
    }

    private var exploreAction: PolymarketPlaceholderView.Action {
        PolymarketPlaceholderView.Action(
            title: Localization.predictionMainExploreEvents,
            icon: DesignSystem.Icons.Globe.regular20,
            handler: { viewModel.handleViewAction(.exploreTapped) }
        )
    }

    private var paginationFooter: some View {
        paginationFooterContent
            .animation(.default, value: viewModel.loadingState == .paginationError)
    }

    @ViewBuilder
    private var paginationFooterContent: some View {
        switch viewModel.loadingState {
        case .loaded:
            paginationLoader
                .id(viewModel.loadedCount)
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
}

// MARK: - Pagination

private extension PolymarketActivityView {
    var paginationLoader: some View {
        Loader()
            .frame(maxWidth: .infinity)
            .padding(.vertical, Constants.paginationVerticalPadding)
    }
}

// MARK: - Constants

private extension PolymarketActivityView {
    enum Constants {
        static let topBarTopPadding: CGFloat = 8
        static let tabsTopPadding: CGFloat = 16
        static let headerBottomPadding: CGFloat = 8
        static let paginationVerticalPadding: CGFloat = 20
        static let skeletonRowCount = 12
    }
}
