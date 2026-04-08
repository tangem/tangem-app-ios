//
//  PulseMarketWidgetViewRedesign.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct PulseMarketWidgetViewRedesign: View {
    @ObservedObject var viewModel: PulseMarketWidgetViewModel

    @Environment(\.mainWindowSize) private var mainWindowSize

    var body: some View {
        VStack(alignment: .leading, spacing: MarketsWidgetLayout.Item.interItemSpacing) {
            header

            if viewModel.isNeedDisplayFilter {
                filter
            }

            list
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

    private var loadingSkeletons: some View {
        VStack(spacing: .zero) {
            ForEach(0 ..< 5) { _ in
                MarketsSkeletonItemView()
            }
        }
    }

    private var list: some View {
        Group {
            switch viewModel.tokenViewModelsState {
            case .loading:
                loadingSkeletons
                    .transition(.opacity.animation(.easeInOut))
            case .success(let tokenViewModels):
                VStack(spacing: .zero) {
                    ForEach(tokenViewModels) {
                        MarketTokenRowView(viewModel: $0)
                    }
                }
                .transition(.opacity.animation(.easeInOut))
            case .failure:
                MarketsWidgetErrorView(tryLoadAgain: viewModel.tryLoadAgain)
                    .transition(.opacity.animation(.easeInOut))
            }
        }
        .roundedBackground(with: .Tangem.Surface.level3, padding: .zero, radius: .unit(.x5))
    }

    private var filter: some View {
        HorizontalChipsView(
            chips: viewModel.availabilityToSelectionOrderType.map { Chip(id: $0.rawValue, title: $0.description) },
            selectedId: $viewModel.filterSelectedId,
            horizontalInset: 4
        )
    }
}
