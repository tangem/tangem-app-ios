//
//  EarnBestOpportunitiesListView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemUI
import TangemUIUtils

struct EarnBestOpportunitiesListView: View {
    let resultState: LoadingResult<[EarnTokenItemViewModel], Error>
    let retryAction: () -> Void

    var body: some View {
        switch resultState {
        case .loading:
            loadingSkeletons
        case .success(let viewModels):
            opportunitiesList(viewModels: viewModels)
        case .failure:
            errorView
        }
    }

    private var loadingSkeletons: some View {
        VStack(spacing: .zero) {
            ForEach(0 ..< 5) { _ in
                MarketsSkeletonItemView()
            }
        }
        .padding(.horizontal, Layout.horizontalPadding)
    }

    private func opportunitiesList(viewModels: [EarnTokenItemViewModel]) -> some View {
        LazyVStack(spacing: Layout.itemSpacing) {
            ForEach(viewModels) { viewModel in
                EarnTokenItemView(viewModel: viewModel)
            }
        }
        .padding(.horizontal, Layout.horizontalPadding)
    }

    private var errorView: some View {
        UnableToLoadDataView(
            isButtonBusy: false,
            retryButtonAction: retryAction
        )
        .infinityFrame(axis: .horizontal, alignment: .center)
        .frame(maxHeight: Layout.defaultMaxHeight)
        .defaultRoundedBackground(
            with: Colors.Background.action,
            verticalPadding: Layout.verticalPadding,
            horizontalPadding: Layout.horizontalPadding
        )
        .padding(.horizontal, Layout.horizontalPadding)
    }
}

private extension EarnBestOpportunitiesListView {
    enum Layout {
        static let itemSpacing: CGFloat = .zero
        static let horizontalPadding: CGFloat = 16.0
        static let verticalPadding: CGFloat = 34
        static let defaultMaxHeight: CGFloat = 130
    }
}
