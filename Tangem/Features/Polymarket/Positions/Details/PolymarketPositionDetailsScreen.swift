//
//  PolymarketPositionDetailsScreen.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemPolymarketUI
import TangemUI
import TangemUIUtils

struct PolymarketPositionDetailsScreen: View {
    @ObservedObject var viewModel: PolymarketPositionDetailsViewModel

    var body: some View {
        PolymarketPositionDetailsView(model: viewModel.model) { viewModel.handleViewAction(.close) }
            .onWillDisappear { viewModel.handleViewAction(.onDisappear) }
            .alert(item: $viewModel.alert) { $0.alert }
            .modal(
                item: $viewModel.hint,
                header: { hint in
                    FeedModalHeaderView(title: hint.title, onClose: { viewModel.hint = nil })
                },
                content: { hint in
                    PolymarketPositionHintSheetView(model: hint)
                },
                footer: { _ in
                    EmptyView()
                }
            )
            .scrollIndicators(.hidden)
    }
}
