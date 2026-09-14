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
                case .eventDetails(let viewModel):
                    PolymarketEventDetailsView(viewModel: viewModel)
                case .positionDetails(let model):
                    PolymarketPositionDetailsView(model: model) { coordinator.destination = nil }
                        .background(FeedPopGestureEnabler())
                        .sheet(item: $coordinator.positionHint) { hint in
                            PolymarketPositionHintSheetView(model: hint)
                                .presentationDetents(idealHeight: Constants.positionHintSheetHeight)
                                .presentationBackground(DesignSystem.Color.bgPrimary)
                        }
                }
            }
            .navigation(item: $coordinator.orderCoordinator) { coordinator in
                PolymarketOrderCoordinatorView(coordinator: coordinator)
            }
            .navigation(item: $coordinator.tokenDetailsCoordinator) { coordinator in
                TokenDetailsCoordinatorView(coordinator: coordinator)
            }
    }
}

// MARK: - Constants

private extension PolymarketCoordinatorView {
    enum Constants {
        static let positionHintSheetHeight: CGFloat = 180
    }
}
