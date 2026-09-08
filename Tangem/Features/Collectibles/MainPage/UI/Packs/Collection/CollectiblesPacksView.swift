//
//  CollectiblesPacksView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
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
                CollectiblesPackGrid(models: models, onLastItemAppear: viewModel.loadMore)
                paginationFooter
            }
        case .empty(let hasQuery):
            EmptyMessage(
                icon: hasQuery ? DesignSystem.Icons.Binoculars.regular20 : DesignSystem.Icons.Stack.regular20,
                message: emptyMessage(hasQuery: hasQuery),
                onRetry: nil
            )
            .frame(minHeight: Constants.messageMinHeight)
        case .failed(let hasQuery):
            EmptyMessage(
                icon: DesignSystem.Icons.ArrowRefresh.regular20,
                message: failedMessage(hasQuery: hasQuery),
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
    // [REDACTED_TODO_COMMENT]
    func emptyMessage(hasQuery: Bool) -> String {
        hasQuery
            ? "No results. Try to change your wording\nor explore from the list"
            : "There are no packs here yet"
    }

    // [REDACTED_TODO_COMMENT]
    func failedMessage(hasQuery: Bool) -> String {
        hasQuery ? "Failed to load cards list.\nTap to reload" : "Failed to load packs.\nTap to reload"
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

#Preview {
    ZStack {
        DesignSystem.Color.bgPrimary.ignoresSafeArea()

        ScrollView {
            CollectiblesPacksView(viewModel: CollectiblesPacksViewModel(model: CollectiblesPacksModel(provider: CollectiblesPacksMockProvider())))
        }
    }
}
