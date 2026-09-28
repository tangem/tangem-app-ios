//
//  CollectiblesPrizePoolView.swift
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

struct CollectiblesPrizePoolView: View {
    @ObservedObject var viewModel: CollectiblesPrizePoolViewModel

    var body: some View {
        switch viewModel.state {
        case .loading:
            section { CollectiblesPrizeGrid.Skeleton() }
        case .content(let models):
            section {
                CollectiblesPrizeGrid(models: models, onLastItemAppear: viewModel.loadMore)
                paginationFooter
            }
        case .failed:
            // The mockup drops the section header along with the pool, the message stands on its own.
            CollectiblesEmptyMessage(
                icon: DesignSystem.Icons.ArrowRefresh.regular20,
                message: Localization.collectiblesMachinePrizePoolLoadError,
                onRetry: viewModel.retry
            )
            .frame(height: Metrics.messageHeight)
        case .empty:
            EmptyView()
        }
    }
}

private extension CollectiblesPrizePoolView {
    // MARK: - View properties

    func section(@ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Localization.collectiblesMachinePrizePoolSection)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                .padding(.vertical, Metrics.headerVerticalPadding)

            content()
                .padding(.top, Metrics.contentTopPadding)
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
                .padding(.vertical, Metrics.paginationVerticalPadding)
        case .failed:
            TangemUnableToLoadDataView(isButtonBusy: false, retryButtonAction: viewModel.loadMore)
                .infinityFrame(axis: .horizontal)
                .padding(.vertical, Metrics.paginationVerticalPadding)
        }
    }
}

// MARK: - Metrics

private extension CollectiblesPrizePoolView {
    enum Metrics {
        static let headerVerticalPadding: CGFloat = 10
        static let contentTopPadding: CGFloat = 12
        static let paginationVerticalPadding: CGFloat = 16
        static let messageHeight: CGFloat = 320
    }
}
