//
//  PolymarketCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemUIUtils

struct PolymarketCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: PolymarketCoordinator

    var body: some View {
        content
            .injectMarketsNavigationConfigurator(isSimplified: true)
            .navigation(item: $coordinator.eventDetailsViewModel) { viewModel in
                PolymarketEventDetailsView(viewModel: viewModel)
            }
            .floatingSheetContent(for: PolymarketRegionRestrictionViewModel.self) { viewModel in
                PolymarketRegionRestrictionView(viewModel: viewModel)
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
}
