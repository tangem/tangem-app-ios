//
//  PolymarketActivityCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemPolymarketUI
import TangemUI
import TangemUIUtils

struct PolymarketActivityCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: PolymarketActivityCoordinator

    var body: some View {
        content
            .modal(
                item: $coordinator.details,
                header: { viewModel in
                    PolymarketActivityDetailsView.header(
                        model: viewModel.model,
                        onClose: { viewModel.handleViewAction(.closeTapped) }
                    )
                },
                content: { viewModel in
                    PolymarketActivityDetailsView(model: viewModel.model)
                        .legacyFooter {
                            if viewModel.canGoToPredict {
                                PolymarketActivityDetailsView.footer(onGoToPredict: { viewModel.handleViewAction(.goToPredictTapped) })
                            }
                        }
                }
            )
            .scrollIndicators(.hidden)
            .navigationLinks(links)
    }

    @ViewBuilder
    private var content: some View {
        if let viewModel = coordinator.rootViewModel {
            PolymarketActivityView(viewModel: viewModel)
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
