//
//  GachaPacksView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct GachaPacksView: View {
    @ObservedObject var viewModel: GachaPacksViewModel

    var body: some View {
        content.task(viewModel.load)
    }
}

// MARK: - Content

private extension GachaPacksView {
    // MARK: - View properties

    @ViewBuilder
    var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            GachaPackGrid.Skeleton(cellsCount: Constants.skeletonCellsCount)
        case .content(let models):
            GachaPackGrid(models: models)
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
}

// MARK: - Copy

private extension GachaPacksView {
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

private extension GachaPacksView {
    enum Constants {
        static let skeletonCellsCount = 4
        static let messageMinHeight: CGFloat = 320
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        DesignSystem.Color.bgPrimary.ignoresSafeArea()

        ScrollView {
            GachaPacksView(viewModel: GachaPacksViewModel(provider: GachaPacksMockProvider()))
        }
    }
}
