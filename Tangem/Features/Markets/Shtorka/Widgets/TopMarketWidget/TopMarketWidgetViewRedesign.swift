//
//  TopMarketWidgetViewRedesign.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct TopMarketWidgetViewRedesign: View {
    @ObservedObject var viewModel: TopMarketWidgetViewModel

    var body: some View {
        // `contentSpacing` (12) + the header's 8pt bottom padding = the 20pt "Market" → island gap.
        VStack(alignment: .leading, spacing: Layout.contentSpacing) {
            header
                .disableAnimations()

            list
                .roundedBackground(with: .Tangem.Surface.level3, padding: .zero, radius: .unit(.x6))
                .id(listStateID)
                .transition(.opacity)

            promotion
        }
        // Lifts the "Market" header to a 44pt gap below the date, without touching the shared widgets inset.
        .padding(.top, Layout.topInset)
        .animation(.easeInOut(duration: 0.3), value: listStateID)
    }

    private enum Layout {
        static let contentSpacing: CGFloat = 12
        static let topInset: CGFloat = 6
    }

    private var listStateID: Int {
        switch viewModel.tokenViewModelsState {
        case .loading: return 0
        case .success: return 1
        case .failure: return 2
        }
    }

    private var header: some View {
        MarketsCommonWidgetHeaderViewRedesign(
            headerTitle: viewModel.widgetType.headerTitle ?? "",
            headerImage: nil,
            buttonTitle: Localization.commonSeeAll,
            buttonAction: viewModel.onSeeAllTapAction,
            isLoadingState: viewModel.headerLoadingState
        )
    }

    @ViewBuilder
    private var promotion: some View {
        PromotionNotificationsView(viewModel: viewModel.promotionNotificationsViewModel)
    }

    @ViewBuilder
    private var list: some View {
        switch viewModel.tokenViewModelsState {
        case .loading:
            loadingSkeletons

        case .success(let tokenViewModels):
            VStack(spacing: .zero) {
                ForEach(tokenViewModels) {
                    MarketTokenRowView(viewModel: $0)
                }
            }

        case .failure:
            TangemUnableToLoadDataView(
                isButtonBusy: false,
                retryButtonAction: viewModel.tryLoadAgain
            )
            .infinityFrame(axis: .horizontal, alignment: .center)
            // No ScaledMetric because this padding is huge
            .padding(.vertical, 142)
        }
    }

    private var loadingSkeletons: some View {
        VStack(spacing: .zero) {
            ForEach(0 ..< viewModel.itemsOnListWidget, id: \.self) { _ in
                TangemTwoLineRowSkeletonView()
            }
        }
    }
}
