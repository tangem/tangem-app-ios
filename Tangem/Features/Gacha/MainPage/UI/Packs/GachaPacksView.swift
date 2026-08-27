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
        case .empty:
            // [REDACTED_TODO_COMMENT]
            EmptyMessage(
                icon: DesignSystem.Icons.Stack.regular20,
                message: "There are no packs here yet",
                onRetry: nil
            )
        case .failed:
            // [REDACTED_TODO_COMMENT]
            EmptyMessage(
                icon: DesignSystem.Icons.ArrowRefresh.regular20,
                message: "Failed to load packs.\nTap to reload",
                onRetry: viewModel.reload
            )
        }
    }
}

// MARK: - Constants

private extension GachaPacksView {
    enum Constants {
        static let skeletonCellsCount = 4
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
