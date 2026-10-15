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
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            .background(PopGestureDisabler(isDisabled: coordinator.disablesPopGesture))
            .navigationLinks(links)
            .polymarketOrderSheet(presenter: coordinator.orderPresenter, host: coordinator)
    }

    @ViewBuilder
    private var content: some View {
        if let viewModel = coordinator.rootViewModel {
            PolymarketPositionDetailsScreen(viewModel: viewModel)
        }
    }

    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.destination) { destination in
                switch destination {
                case .eventDetails(let coordinator):
                    PolymarketEventDetailsCoordinatorView(coordinator: coordinator)
                }
            }
    }
}
