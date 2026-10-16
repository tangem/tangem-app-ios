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
        ZStack(alignment: .top) {
            pool
        }
    }
}

private extension CollectiblesPrizePoolView {
    // MARK: - View properties

    @ViewBuilder
    var pool: some View {
        switch viewModel.state {
        case .loading:
            section(header: { CollectiblesMachineView.HeadingBar() }, content: { CollectiblesPrizeGrid.Skeleton() })
                .padding(.top, CollectiblesMachineView.Metrics.sectionsGap)
                .transition(.content)
        case .content(let models):
            section(header: { heading }) {
                CollectiblesPrizeGrid(models: models, onLastItemAppear: viewModel.loadMore)
                paginationFooter
            }
            .padding(.top, CollectiblesMachineView.Metrics.sectionsGap)
            .transition(.content)
        case .failed(let isRetrying):
            // The mockup drops the section header along with the pool, the message stands on its own.
            CollectiblesEmptyMessage(
                icon: DesignSystem.Icons.ArrowRefresh.regular20,
                message: Localization.collectiblesMachinePrizePoolLoadError,
                onRetry: viewModel.retry,
                isRetrying: isRetrying
            )
            .frame(height: Metrics.messageHeight)
            .padding(.top, CollectiblesMachineView.Metrics.sectionsGap)
            .transition(.content)
        }
    }

    func section(@ViewBuilder header: () -> some View, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            header()
                .padding(.vertical, Metrics.headerVerticalPadding)

            content()
                .padding(.top, Metrics.contentTopPadding)
        }
    }

    var heading: some View {
        Text(Localization.collectiblesMachinePrizePoolSection)
            .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
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
            CollectiblesEmptyMessage(
                icon: DesignSystem.Icons.ArrowRefresh.regular20,
                message: Localization.marketsLoadingErrorTitle,
                onRetry: viewModel.loadMore,
                verticalPadding: Metrics.paginationVerticalPadding
            )
        }
    }
}

// MARK: - Transitions

private extension AnyTransition {
    static let content = AnyTransition.opacity.animation(.curve(.easeInOutRefined, duration: 0.3))
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
