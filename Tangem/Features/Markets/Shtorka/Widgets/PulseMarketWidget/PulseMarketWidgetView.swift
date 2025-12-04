//
//  PulseMarketWidgetView.swift
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

struct PulseMarketWidgetView: View {
    @ObservedObject var viewModel: PulseMarketWidgetViewModel

    @Environment(\.mainWindowSize) private var mainWindowSize

    var body: some View {
        VStack(alignment: .leading, spacing: MarketsWidgetLayout.Item.interItemSpacing) {
            header
                .padding(.horizontal, MarketsWidgetLayout.Header.horizontalPadding)

            filter

            list
                .padding(.horizontal, MarketsWidgetLayout.Item.horizontalPadding)
        }
    }

    private var header: some View {
        MarketsCommonWidgetHeaderView(
            headerTitle: viewModel.widgetType.headerTitle ?? "",
            buttonTitle: Localization.commonSeeAll,
            buttonAction: nil,
            isLoading: viewModel.loadingState == .idle
        )
    }

    private var loadingSkeletons: some View {
        ForEach(0 ..< 5) { _ in
            MarketsSkeletonItemView()
        }
    }

    private var list: some View {
        Group {
            switch viewModel.loadingState {
            case .loading, .idle:
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
        .defaultRoundedBackground(
            with: Colors.Background.action,
            verticalPadding: MarketsWidgetLayout.Content.innerContentPadding,
            horizontalPadding: MarketsWidgetLayout.Content.innerContentPadding
        )
    }

    private var filter: some View {
        HorizontalChipsView(
            chips: viewModel.availabilityToSelectionOrderType.map { Chip(id: $0.rawValue, title: $0.description) },
            selectedId: $viewModel.filterSelectedId
        )
    }
}

// MARK: - Auxiliary types

extension PulseMarketWidgetView {
    enum ListLoadingState: String, Identifiable, Hashable {
        case loading
        case loaded
        case idle

        var id: String { rawValue }
    }
}

// MARK: - Layout

extension PulseMarketWidgetView {
    enum Layout {
        enum RootView {
            static let verticalContentSpacing: CGFloat = 8.0
        }
    }
}
