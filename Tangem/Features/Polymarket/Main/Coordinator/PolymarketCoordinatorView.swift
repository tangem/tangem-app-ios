//
//  PolymarketCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemPolymarketUI
import TangemUI
import TangemUIUtils

struct PolymarketCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: PolymarketCoordinator

    var body: some View {
        content
            .injectMarketsNavigationConfigurator(isSimplified: true)
            .navigationLinks(links)
            .floatingSheetContent(for: PolymarketRegionRestrictionViewModel.self) { viewModel in
                PolymarketRegionRestrictionView(viewModel: viewModel)
            }
            .floatingSheetContent(for: PolymarketAddFundsSheetViewModel.self) { viewModel in
                PolymarketAddFundsSheetView(viewModel: viewModel)
            }
            .floatingSheetContent(for: ReceiveMainViewModel.self) { viewModel in
                ReceiveMainView(viewModel: viewModel)
            }
    }

    @ViewBuilder
    private var content: some View {
        switch coordinator.viewState {
        case .welcome(let viewModel):
            PolymarketWelcomeView(viewModel: viewModel)
        case .feed(let viewModel):
            PolymarketMainView(viewModel: viewModel)
        case nil:
            EmptyView()
        }
    }

    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.destination) { destination in
                switch destination {
                case .eventDetails(let viewModel):
                    PolymarketEventDetailsView(viewModel: viewModel)
                case .order(let coordinator):
                    PolymarketOrderCoordinatorView(coordinator: coordinator)
                }
            }
    }
}
