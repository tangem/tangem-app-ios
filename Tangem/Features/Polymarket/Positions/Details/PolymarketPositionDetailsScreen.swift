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
        content
            .onWillDisappear { viewModel.handleViewAction(.onDisappear) }
            .alert(item: $viewModel.alert) { $0.alert }
            .modal(
                item: $viewModel.hint,
                header: { hint in
                    FeedModalHeaderView(title: hint.title, onClose: { viewModel.hint = nil })
                },
                content: { hint in
                    PolymarketPositionHintSheetView(model: hint)
                }
            )
            .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.usesPhaseTwoLayout {
            PolymarketPositionDetailsPhaseTwoView(model: viewModel.phaseTwoModel) { viewModel.handleViewAction(.close) }
        } else {
            PolymarketPositionDetailsView(model: viewModel.model) { viewModel.handleViewAction(.close) }
        }
    }
}
