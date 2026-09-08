//
//  PolymarketOrderCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct PolymarketOrderCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: PolymarketOrderCoordinator

    var body: some View {
        coordinator.viewModel.map { viewModel in
            PolymarketOrderView(viewModel: viewModel)
                .sheet(item: $coordinator.slippageSelector) { viewModel in
                    PolymarketSlippageSelectorView(viewModel: viewModel)
                }
        }
    }
}
