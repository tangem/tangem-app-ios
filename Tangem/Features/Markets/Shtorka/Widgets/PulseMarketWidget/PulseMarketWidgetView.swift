//
//  PulseMarketWidgetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct PulseMarketWidgetView: View {
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
        MarketsCommonWidgetHeaderView(
            headerTitle: viewModel.widgetType.headerTitle ?? "",
            headerImage: nil,
            buttonTitle: Localization.commonSeeAll,
            buttonAction: viewModel.onSeeAllTapAction,
            isLoading: viewModel.isFirstLoading
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
            case .success(let tokenViewModels):
                VStack(spacing: .zero) {
                    ForEach(tokenViewModels) {
                        MarketTokenItemView(viewModel: $0, cellWidth: mainWindowSize.width)
                    }
                }
            case .failure:
                MarketsWidgetErrorView(tryLoadAgain: viewModel.tryLoadAgain)
            }
        }
        .defaultRoundedBackground(
            with: Colors.Background.action,
            verticalPadding: MarketsWidgetLayout.Content.innerContentPadding,
            horizontalPadding: MarketsWidgetLayout.Content.innerContentPadding
        )
        .padding(.horizontal, MarketsWidgetLayout.Item.horizontalPadding)
    }

    private var filter: some View {
        HorizontalChipsView(
            chips: viewModel.availabilityToSelectionOrderType.map { Chip(id: $0.rawValue, title: $0.description) },
            selectedId: $viewModel.filterSelectedId
        )
    }
}
