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
            .sheet(item: $coordinator.sheet) { sheet in
                switch sheet {
                case .send(let coordinator):
                    SendCoordinatorView(coordinator: coordinator)
                case .supportChat(let viewModel):
                    supportChat(viewModel: viewModel)
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch coordinator.viewState {
        case .welcome(let viewModel):
            PolymarketWelcomeView(viewModel: viewModel)
        case .main(let viewModel, let balanceBlock, let positionsBlock, let searchBlock, _, _):
            PolymarketMainView(viewModel: viewModel, balanceBlock: balanceBlock, positionsBlock: positionsBlock, searchBlock: searchBlock)
        case nil:
            EmptyView()
        }
    }

    private func supportChat(viewModel: SupportChatViewModel) -> some View {
        NavigationStack {
            SupportChatView(viewModel: viewModel)
                .toolbar {
                    NavigationToolbarButton.close(placement: .topBarLeading) { coordinator.sheet = nil }
                }
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
                case .myPositions(let coordinator):
                    PolymarketMyPositionsCoordinatorView(coordinator: coordinator)
                case .order(let coordinator):
                    PolymarketOrderCoordinatorView(coordinator: coordinator)
                case .tokenDetails(let coordinator):
                    TokenDetailsCoordinatorView(coordinator: coordinator)
                case .redeem(let viewModel):
                    PolymarketRedeemView(viewModel: viewModel)
                }
            }
    }
}
