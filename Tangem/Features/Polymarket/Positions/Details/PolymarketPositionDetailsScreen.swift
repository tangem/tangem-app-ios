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
        PolymarketPositionDetailsView(model: viewModel.model) { viewModel.onCloseTap() }
            .sheet(item: $viewModel.hint) { hint in
                PolymarketPositionHintSheetView(model: hint)
                    .presentationDetents(idealHeight: Constants.hintSheetHeight)
                    .presentationBackground(DesignSystem.Color.bgPrimary)
            }
    }
}

// MARK: - Constants

private extension PolymarketPositionDetailsScreen {
    enum Constants {
        static let hintSheetHeight: CGFloat = 180
    }
}
