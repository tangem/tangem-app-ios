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
import TangemUIUtils

struct PulseMarketWidgetViewRedesign: View {
    @ObservedObject var viewModel: PulseMarketWidgetViewModel

    var showsSeeAllButton: Bool = true

    @Environment(\.mainWindowSize) private var mainWindowSize

    private var listStateID: Int {
        switch viewModel.tokenViewModelsState {
        case .loading: return 0
        case .success: return 1
        case .failure: return 2
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MarketsWidgetLayout.Item.interItemSpacing) {
            header
                .disableAnimations()

            if viewModel.isNeedDisplayFilter {
                filter
            } else if case .loading = viewModel.tokenViewModelsState {
                filterSkeletons
            }

            list
                .roundedBackground(with: .Tangem.Surface.level3, padding: .zero, radius: .unit(.x6))
                .id(listStateID)
                .transition(.opacity)
        }
        .animation(.easeInOut(duration: 0.3), value: listStateID)
    }

    private var header: some View {
        MarketsCommonWidgetHeaderViewRedesign(
            headerTitle: viewModel.widgetType.headerTitle ?? "",
            headerImage: nil,
            buttonTitle: showsSeeAllButton ? Localization.commonSeeAll : nil,
            buttonAction: showsSeeAllButton ? viewModel.onSeeAllTapAction : nil,
            isLoadingState: viewModel.headerLoadingState
        )
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
            TangemUnableToLoadDataView(isButtonBusy: false, retryButtonAction: viewModel.tryLoadAgain)
                .infinityFrame(axis: .horizontal, alignment: .center)
                .padding(.vertical, 132)
        }
    }

    private var filter: some View {
        HorizontalChipsView(
            chips: viewModel.availabilityToSelectionOrderType.map { Chip(id: $0.rawValue, title: $0.description) },
            selectedId: $viewModel.filterSelectedId,
            horizontalInset: 4,
            chipHorizontalPadding: 12
        )
    }

    private var loadingSkeletons: some View {
        VStack(spacing: .zero) {
            ForEach(0 ..< 5, id: \.self) { _ in
                TangemTwoLineRowSkeletonView()
            }
        }
    }

    private var filterSkeletons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .unit(.x2)) {
                SkeletonView()
                    .frame(width: 113, height: 36)
                    .clipShape(.capsule)

                SkeletonView()
                    .frame(width: 113, height: 36)
                    .clipShape(.capsule)

                SkeletonView()
                    .frame(width: 200, height: 36)
                    .clipShape(.capsule)
            }
            .padding(.horizontal, SizeUnit.x4.value)
        }
        .scrollDisabled(true)
        .padding(.horizontal, -SizeUnit.x4.value)
        .allowsHitTesting(false)
    }
}
