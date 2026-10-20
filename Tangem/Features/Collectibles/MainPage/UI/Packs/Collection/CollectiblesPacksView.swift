//
//  CollectiblesPacksView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct CollectiblesPacksView: View {
    @ObservedObject var viewModel: CollectiblesPacksViewModel

    var body: some View {
        ZStack(alignment: .top) {
            content
        }
        .animation(.easeInOut(duration: Constants.appearanceDuration), value: viewModel.state.isLoading)
        .animation(.easeInOut(duration: Constants.appearanceDuration), value: viewModel.loreID)
        .task(viewModel.load)
    }
}

// MARK: - Content

private extension CollectiblesPacksView {
    // MARK: - View properties

    @ViewBuilder
    var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            CollectiblesPackGrid.Skeleton(cellsCount: Constants.skeletonCellsCount)
        case .content(let models):
            grid(models)
        case .empty(let hasQuery):
            emptyView(hasQuery: hasQuery)
        case .reloading(.content(let models)):
            grid(models)
                .opacity(Constants.reloadingOpacity)
                .disabled(true)
        case .reloading(.empty(let hasQuery)):
            emptyView(hasQuery: hasQuery)
                .opacity(Constants.reloadingOpacity)
        case .failed:
            CollectiblesEmptyMessage(
                icon: DesignSystem.Icons.ArrowRefresh.regular20,
                message: Localization.collectiblesMainPacksLoadError,
                onRetry: viewModel.reload
            )
            .frame(minHeight: Constants.messageMinHeight)
        }
    }

    func grid(_ models: [CollectiblesPackCard.Model]) -> some View {
        VStack(spacing: 0) {
            CollectiblesPackGrid(
                models: models,
                onLastItemAppear: viewModel.loadMore,
                onSelect: viewModel.selectPack
            )
            paginationFooter
        }
        .id(viewModel.loreID)
    }

    func emptyView(hasQuery: Bool) -> some View {
        CollectiblesEmptyMessage(
            icon: hasQuery ? DesignSystem.Icons.Binoculars.regular20 : DesignSystem.Icons.Stack.regular20,
            message: emptyMessage(hasQuery: hasQuery),
            onRetry: nil
        )
        .frame(minHeight: Constants.messageMinHeight)
    }

    @ViewBuilder
    var paginationFooter: some View {
        switch viewModel.paginationState {
        case .none, .ready:
            EmptyView()
        case .loading:
            Loader()
                .infinityFrame(axis: .horizontal)
                .padding(.vertical, Constants.paginationVerticalPadding)
        case .failed:
            CollectiblesEmptyMessage(
                icon: DesignSystem.Icons.ArrowRefresh.regular20,
                message: Localization.marketsLoadingErrorTitle,
                onRetry: viewModel.loadMore,
                verticalPadding: Constants.paginationVerticalPadding
            )
        }
    }
}

// MARK: - Copy

private extension CollectiblesPacksView {
    func emptyMessage(hasQuery: Bool) -> String {
        hasQuery ? Localization.collectiblesMainSearchEmpty : Localization.collectiblesMainPacksEmpty
    }
}

// MARK: - Constants

private extension CollectiblesPacksView {
    enum Constants {
        static let skeletonCellsCount = 4
        static let reloadingOpacity: CGFloat = 0.4
        static let messageMinHeight: CGFloat = 320
        static let paginationVerticalPadding: CGFloat = 16
        static let appearanceDuration: TimeInterval = 0.3
    }
}

// MARK: - Previews

private struct PreviewPacksProvider: CollectiblesPacksProvider {
    func load(loreID: String?, query: String, cursor: String?) async throws -> CollectiblesPacksPage {
        let packs = (1 ... 4).map { index in
            CollectiblesPack(
                id: "pack-\(index)",
                loreID: "pokemon",
                currencyCode: "USD",
                machine: CollectiblesMachine(
                    name: "Elite \(index)",
                    artworkURL: nil,
                    price: Decimal(50 * index),
                    platformFee: 1,
                    cardsPerPack: 1,
                    buybackRate: 0.85,
                    expectedValue: Decimal(55 * index),
                    tiers: []
                )
            )
        }
        return CollectiblesPacksPage(packs: packs, hasNext: false, cursor: nil)
    }
}

#Preview {
    ZStack {
        DesignSystem.Color.bgPrimary.ignoresSafeArea()

        ScrollView {
            CollectiblesPacksView(viewModel: CollectiblesPacksViewModel(
                model: CollectiblesPacksModel(provider: PreviewPacksProvider()),
                packSelectionHandler: { _ in }
            ))
        }
    }
}
