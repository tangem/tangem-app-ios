//
//  PolymarketEventDetailsCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils

struct PolymarketEventDetailsCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: PolymarketEventDetailsCoordinator

    var body: some View {
        content
            .navigationLinks(links)
            .polymarketOrderSheet(presenter: coordinator.orderPresenter, host: coordinator)
    }

    @ViewBuilder
    private var content: some View {
        if let viewModel = coordinator.rootViewModel {
            PolymarketEventDetailsView(viewModel: viewModel)
        }
    }

    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.destination) { destination in
                switch destination {
                case .positionDetails(let coordinator):
                    PolymarketPositionDetailsCoordinatorView(coordinator: coordinator)
                }
            }
    }
}
