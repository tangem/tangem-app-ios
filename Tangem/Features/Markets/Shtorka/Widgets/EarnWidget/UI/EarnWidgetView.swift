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

    var body: some View {
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
            isLoading: viewModel.isFirstLoading
        )
    }

    private var list: some View {
        Group {
            switch viewModel.resultState {
            case .loading:
                loadingSkeletons
            case .success(let tokenViewModels):
                VStack(spacing: .zero) {
                    ForEach(tokenViewModels) { tokenViewModel in
                        EarnTokenItemView(viewModel: tokenViewModel)
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

    private var loadingSkeletons: some View {
        VStack(spacing: .zero) {
            ForEach(0 ..< 5) { _ in
                MarketsSkeletonItemView()
            }
        }
    }
}
