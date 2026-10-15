//
//  PolymarketPositionsBlockView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemPolymarketUI

struct PolymarketPositionsBlockView: View {
    @ObservedObject var viewModel: PolymarketPositionsBlockViewModel

    var body: some View {
        switch viewModel.content {
        case .hidden:
            EmptyView()
        case .skeleton:
            container {
                PolymarketPositionsSkeletonView(rowCount: Constants.skeletonRowCount)
            }
        case .failed:
            container {
                PolymarketEmptyMessageView(
                    message: Localization.predictionPositionsLoadError,
                    onRetry: { viewModel.handleViewAction(.retry) }
                )
            }
        case .positions(let models, let showsViewAll):
            container {
                PolymarketPositionsListView(
                    models: models,
                    showsViewAll: showsViewAll,
                    onOpenPosition: { viewModel.handleViewAction(.openPositionDetails(id: $0)) },
                    onViewAll: { viewModel.handleViewAction(.openMyPositions(.active)) }
                )
            }
        case .noActivePositions(let showsViewAll):
            container {
                PolymarketNoActivePositionsBlockContent(
                    showsViewAll: showsViewAll,
                    onViewAll: { viewModel.handleViewAction(.openMyPositions(.active)) }
                )
            }
        }
    }
}

// MARK: - Subviews

private extension PolymarketPositionsBlockView {
    func container(@ViewBuilder content: () -> some View) -> some View {
        PolymarketPositionsBlockContainer(
            hasFinishedPositions: viewModel.hasFinishedPositions,
            onOpenFinished: { viewModel.handleViewAction(.openMyPositions(.finished)) },
            content: content
        )
    }
}

// MARK: - Constants

private extension PolymarketPositionsBlockView {
    enum Constants {
        static let skeletonRowCount = 3
    }
}
