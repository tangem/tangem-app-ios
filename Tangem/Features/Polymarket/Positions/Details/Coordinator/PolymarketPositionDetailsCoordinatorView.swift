//
//  PolymarketPositionDetailsCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils

struct PolymarketPositionDetailsCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: PolymarketPositionDetailsCoordinator

    var body: some View {
        content
            .navigationLinks(links)
    }

    @ViewBuilder
    private var content: some View {
        if let viewModel = coordinator.rootViewModel {
            PolymarketPositionDetailsScreen(viewModel: viewModel)
                .background(FeedPopGestureEnabler())
        }
    }

    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.destination) { destination in
                switch destination {
                case .order(let coordinator):
                    PolymarketOrderCoordinatorView(coordinator: coordinator)
                }
            }
    }
}
