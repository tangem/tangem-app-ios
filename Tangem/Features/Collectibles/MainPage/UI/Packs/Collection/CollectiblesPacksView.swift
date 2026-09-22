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
        content.task(viewModel.load)
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
            VStack(spacing: 0) {
                CollectiblesPackGrid(
                    models: models,
                    onLastItemAppear: viewModel.loadMore,
                    onSelect: viewModel.selectPack
                )
                paginationFooter
            }
        case .empty(let hasQuery):
            CollectiblesEmptyMessage(
                icon: hasQuery ? DesignSystem.Icons.Binoculars.regular20 : DesignSystem.Icons.Stack.regular20,
                message: emptyMessage(hasQuery: hasQuery),
                onRetry: nil
            )
            .frame(minHeight: Constants.messageMinHeight)
        case .failed:
            CollectiblesEmptyMessage(
                icon: DesignSystem.Icons.ArrowRefresh.regular20,
                message: Localization.collectiblesMainPacksLoadError,
                onRetry: viewModel.reload
            )
            .frame(minHeight: Constants.messageMinHeight)
        }
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
            TangemUnableToLoadDataView(isButtonBusy: false, retryButtonAction: viewModel.loadMore)
                .infinityFrame(axis: .horizontal)
                .padding(.vertical, Constants.paginationVerticalPadding)
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
        static let messageMinHeight: CGFloat = 320
        static let paginationVerticalPadding: CGFloat = 16
    }
}

// MARK: - Previews

private struct PreviewPacksProvider: CollectiblesPacksProvider {
    func load(loreID: String?, query: String, cursor: String?) async throws -> CollectiblesPacksPage {
        let packs = (1 ... 4).map { index in
            CollectiblesPack(id: "pack-\(index)", name: "Elite \(index)", loreID: "pokemon", price: Decimal(50 * index), currencyCode: "USD", buybackRate: 0.85, artworkURL: nil)
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
