//
//  EarnWidgetViewRedesign.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemUIUtils

struct EarnWidgetViewRedesign: View {
    @ObservedObject var viewModel: EarnWidgetViewModel

    @ViewBuilder
    var body: some View {
        if viewModel.hasContent {
            rootView
        }
    }

    private var listStateID: Int {
        switch viewModel.resultState {
        case .loading: return 0
        case .success: return 1
        case .failure: return 2
        }
    }

    private var rootView: some View {
        VStack(alignment: .leading, spacing: MarketsWidgetLayout.Item.interItemSpacing) {
            header
                .disableAnimations()

            list
                .id(listStateID)
                .transition(.opacity)
        }
        .animation(.easeInOut(duration: 0.3), value: listStateID)
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
    private var list: some View {
        switch viewModel.resultState {
        case .loading:
            loadingSkeletons

        case .success(let tokenViewModels):
            // Negative padding bleeds the carousel past the 16pt horizontal padding
            // that MarketsMainView applies to the entire widget container.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .unit(.x2)) {
                    ForEach(tokenViewModels) { tokenViewModel in
                        EarnTokenTileView(viewModel: tokenViewModel)
                    }
                }
                .padding(.horizontal, SizeUnit.x4.value)
            }
            .padding(.horizontal, -SizeUnit.x4.value)

        case .failure:
            TangemUnableToLoadDataView(isButtonBusy: false, retryButtonAction: viewModel.tryLoadAgain)
                .infinityFrame(axis: .horizontal, alignment: .center)
                .padding(.vertical, 37)
        }
    }

    private var loadingSkeletons: some View {
        // Negative padding bleeds the carousel past the 16pt horizontal padding
        // that MarketsMainView applies to the entire widget container.
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .unit(.x2)) {
                EarnTokenTileSkeletonView()
                EarnTokenTileSkeletonView()
                EarnTokenTileSkeletonView()
            }
            .padding(.horizontal, SizeUnit.x4.value)
        }
        .scrollDisabled(true)
        .padding(.horizontal, -SizeUnit.x4.value)
    }
}
