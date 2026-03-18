//
//  EarnWidgetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct EarnWidgetView: View {
    @ObservedObject var viewModel: EarnWidgetViewModel

    @ViewBuilder
    var body: some View {
        if viewModel.hasContent {
            rootView
        }
    }

    private var rootView: some View {
        VStack(alignment: .leading, spacing: MarketsWidgetLayout.Item.interItemSpacing) {
            header

            list
        }
    }

    private var header: some View {
        MarketsCommonWidgetHeaderView(
            headerTitle: viewModel.widgetType.headerTitle ?? "",
            headerImage: nil,
            buttonTitle: Localization.commonSeeAll,
            buttonAction: viewModel.onSeeAllTapAction,
            isLoadingState: viewModel.headerLoadingState
        )
    }

    private var list: some View {
        Group {
            switch viewModel.resultState {
            case .loading:
                loadingSkeletons
            case .success(let tokenViewModels):
                if FeatureProvider.isAvailable(.redesign) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: .unit(.x2)) {
                            ForEach(tokenViewModels) { tokenViewModel in
                                EarnTokenTileView(viewModel: tokenViewModel)
                            }
                        }
                    }
                } else {
                    VStack(spacing: .zero) {
                        ForEach(tokenViewModels) { tokenViewModel in
                            EarnTokenItemView(viewModel: tokenViewModel)
                        }
                    }
                    .defaultRoundedBackground(
                        with: Color.Tangem.Surface.level4,
                        verticalPadding: MarketsWidgetLayout.Content.innerContentPadding,
                        horizontalPadding: MarketsWidgetLayout.Content.innerContentPadding
                    )
                }
            case .failure:
                MarketsWidgetErrorView(tryLoadAgain: viewModel.tryLoadAgain)
            }
        }
        .padding(.horizontal, MarketsWidgetLayout.Item.horizontalPadding)
    }

    private var loadingSkeletons: some View {
        VStack(spacing: .zero) {
            ForEach(0 ..< 5) { _ in
                MarketsSkeletonItemView()
            }
        }
    }
}
