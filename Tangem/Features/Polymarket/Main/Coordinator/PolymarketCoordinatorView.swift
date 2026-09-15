//
//  PolymarketCoordinatorView.swift
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

struct PolymarketCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: PolymarketCoordinator

    var body: some View {
        content
            .toolbar(.hidden, for: .navigationBar)
            .background(FeedPopGestureEnabler())
            .navigationLinks(links)
            .sheet(item: $coordinator.sendCoordinator) {
                SendCoordinatorView(coordinator: $0)
            }
    }

    @ViewBuilder
    private var content: some View {
        switch coordinator.viewState {
        case .welcome(let viewModel):
            PolymarketWelcomeView(viewModel: viewModel)
        case .main(let viewModel):
            PolymarketMainView(viewModel: viewModel)
        case nil:
            EmptyView()
        }
    }

    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.destination) { destination in
                switch destination {
                case .eventDetails(let coordinator):
                    PolymarketEventDetailsCoordinatorView(coordinator: coordinator)
                case .positionDetails(let viewModel):
                    PolymarketPositionDetailsScreen(viewModel: viewModel)
                        .background(FeedPopGestureEnabler())
                case .myPositions(let coordinator):
                    PolymarketMyPositionsCoordinatorView(coordinator: coordinator)
                case .order(let coordinator):
                    PolymarketOrderCoordinatorView(coordinator: coordinator)
                }
            }
            .navigation(item: $coordinator.tokenDetailsCoordinator) { coordinator in
                TokenDetailsCoordinatorView(coordinator: coordinator)
            }
    }
}
