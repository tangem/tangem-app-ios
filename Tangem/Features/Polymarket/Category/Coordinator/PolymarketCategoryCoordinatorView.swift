//
//  PolymarketCategoryCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils

struct PolymarketCategoryCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: PolymarketCategoryCoordinator

    var body: some View {
        content
            .navigationLinks(links)
            .polymarketOrderSheet(presenter: coordinator.orderPresenter, host: coordinator)
    }

    @ViewBuilder
    private var content: some View {
        if let viewModel = coordinator.rootViewModel {
            PolymarketCategoryView(viewModel: viewModel)
        }
    }

    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.destination) { destination in
                switch destination {
                case .eventDetails(let coordinator):
                    PolymarketEventDetailsCoordinatorView(coordinator: coordinator)
                case .positionDetails(let coordinator):
                    PolymarketPositionDetailsCoordinatorView(coordinator: coordinator)
                }
            }
    }
}
