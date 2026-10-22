//
//  PulseMarketWidgetView.swift
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

struct PulseMarketWidgetView: View {
    @ObservedObject var viewModel: PulseMarketWidgetViewModel

    var showsSeeAllButton: Bool = true

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
            } else if !viewModel.isSearchActive, case .loading = viewModel.tokenViewModelsState {
                filterSkeletons
            }

            // The states overlap while fading so they dissolve in place instead of pushing each other
            ZStack(alignment: .topLeading) {
                list
                    .id(listStateID)
                    .transition(.content)
            }
            .roundedBackground(with: DesignSystem.Color.bgSecondary, padding: .zero, radius: 24)
        }
        .animation(.contentFrameUpdate, value: listStateID)
    }

    private var header: some View {
        MarketsCommonWidgetHeaderView(
            headerTitle: viewModel.headerTitle,
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
            ForEach(0 ..< viewModel.itemsOnListWidget, id: \.self) { _ in
                TokenRowMarket(.shimmer)
            }
        }
    }

    private var filterSkeletons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chipSkeleton(width: 113)
                chipSkeleton(width: 113)
                chipSkeleton(width: 200)
            }
            .padding(.horizontal, 16)
        }
        .scrollDisabled(true)
        .padding(.horizontal, -16)
        .allowsHitTesting(false)
    }

    /// The chips themselves keep a fixed height, so the placeholder is pinned rather than left to scale.
    private func chipSkeleton(width: CGFloat) -> some View {
        Shimmer()
            .variant(.custom(cornerRadius: Constants.chipCornerRadius))
            .frame(width: width, height: Constants.chipHeight)
    }
}

// MARK: - Constants

private extension PulseMarketWidgetView {
    enum Constants {
        static let chipHeight: CGFloat = 36
        static let chipCornerRadius: CGFloat = 24
    }
}

// MARK: - Content transition

private extension Animation {
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.3)
}

private extension AnyTransition {
    static let content = AnyTransition.opacity.animation(.curve(.easeInOutRefined, duration: 0.3))
}
