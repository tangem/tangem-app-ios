//
//  PulseMarketWidgetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
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
        VStack(alignment: .leading, spacing: Layout.RootView.verticalContentSpacing) {
            filter

            list
        }
    }

    private var loadingSkeletons: some View {
        ForEach(0 ..< 5) { _ in
            MarketsSkeletonItemView()
        }
    }

    private var list: some View {
        VStack(spacing: .zero) {
            ForEach(viewModel.tokenViewModels) {
                MarketTokenItemView(viewModel: $0, cellWidth: mainWindowSize.width)
            }

            // Need for display list skeleton view
            if case .loading = viewModel.tokenListLoadingState {
                loadingSkeletons
            }
        }
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
            static let verticalContentSpacing: CGFloat = 14.0
        }
    }
}
