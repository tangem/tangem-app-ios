//
//  TopMarketWidget.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import Combine
import BlockchainSdk
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemFoundation

struct TopMarketWidgetView: View {
    @ObservedObject var viewModel: TopMarketWidgetViewModel

    @Environment(\.mainWindowSize) private var mainWindowSize

    var body: some View {
        VStack(alignment: .leading, spacing: MarketsWidgetLayout.Item.interItemSpacing) {
            header
                .padding(.horizontal, MarketsWidgetLayout.Header.horizontalPadding)

            content
                .defaultRoundedBackground(
                    with: Colors.Background.action,
                    verticalPadding: MarketsWidgetLayout.Content.innerContentPadding,
                    horizontalPadding: MarketsWidgetLayout.Content.innerContentPadding
                )
                .padding(.horizontal, MarketsWidgetLayout.Item.horizontalPadding)
        }
    }

    private var header: some View {
        MarketsCommonWidgetHeaderView(
            headerTitle: viewModel.widgetType.headerTitle ?? "",
            buttonTitle: Localization.commonSeeAll,
            buttonAction: nil,
            isLoading: viewModel.loadingState == .idle || viewModel.loadingState == .loading
        )
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadingState {
        case .idle, .loading:
            loadingSkeletons
        case .loaded:
            VStack(spacing: .zero) {
                ForEach(viewModel.tokenViewModels) {
                    MarketTokenItemView(viewModel: $0, cellWidth: mainWindowSize.width)
                }
            }
        case .error:
            MarketsMainWidgetErrorView {
                viewModel.tryLoadAgain()
            }
        }
    }

    private var loadingSkeletons: some View {
        ForEach(0 ..< 5) { _ in
            MarketsSkeletonItemView()
        }
    }
}

// MARK: - Layout

extension TopMarketWidgetView {
    enum Layout {
        enum RootView {
            static let verticalContentSpacing: CGFloat = 8.0
        }

        enum List {
            static let horizontalContentPadding: CGFloat = 16.0
        }
    }
}
