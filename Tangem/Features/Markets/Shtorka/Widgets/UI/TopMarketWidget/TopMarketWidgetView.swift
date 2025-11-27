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

    private var defaultBackgroundColor: Color { Colors.Background.primary }

    var body: some View {
        rootView
    }

    @ViewBuilder
    private var rootView: some View {
        list
    }

    @ViewBuilder
    private var list: some View {
        VStack(spacing: 0.0) {
            ForEach(viewModel.tokenViewModels) {
                MarketTokenItemView(viewModel: $0, cellWidth: mainWindowSize.width)
            }

            // Need for display list skeleton view
            if case .loading = viewModel.tokenListLoadingState {
                loadingSkeletons
            }
        }
    }

    private var loadingSkeletons: some View {
        ForEach(0 ..< 5) { _ in
            MarketsSkeletonItemView()
        }
    }
}

// MARK: - Constants

private extension TopMarketWidgetView {
    enum Constants {
        static let defaultHorizontalInset = 16.0
        static let listOverlayTopInset = 10.0
        static let listOverlayBottomInset = 12.0
    }
}

// MARK: - Auxiliary types

extension TopMarketWidgetView {
    enum ListLoadingState: String, Identifiable, Hashable {
        case loading
        case loaded
        case idle

        var id: String { rawValue }
    }
}
