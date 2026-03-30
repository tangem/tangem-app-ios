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
        VStack(alignment: .leading, spacing: MarketsWidgetLayout.Item.interItemSpacing) {
            header

            list

            promotion
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

    private var list: some View {
        Group {
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
                MarketsWidgetErrorView(tryLoadAgain: viewModel.tryLoadAgain)
            }
        }
        .roundedBackground(with: .Tangem.Surface.level3, padding: .zero, radius: .unit(.x5))
    }

    private var loadingSkeletons: some View {
        VStack(spacing: .zero) {
            ForEach(0 ..< 5) { _ in
                MarketsSkeletonItemView()
            }
        }
    }
}
