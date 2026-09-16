//
//  PolymarketMyPositionsCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils

struct PolymarketMyPositionsCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: PolymarketMyPositionsCoordinator

    var body: some View {
        content
            .navigationLinks(links)
    }

    @ViewBuilder
    private var content: some View {
        if let viewModel = coordinator.rootViewModel {
            PolymarketMyPositionsView(viewModel: viewModel)
        }
    }

    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.destination) { destination in
                switch destination {
                case .positionDetails(let viewModel):
                    PolymarketPositionDetailsScreen(viewModel: viewModel)
                case .order(let coordinator):
                    PolymarketOrderCoordinatorView(coordinator: coordinator)
                }
            }
    }
}
