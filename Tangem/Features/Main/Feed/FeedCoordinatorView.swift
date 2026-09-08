//
//  FeedCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct FeedCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: FeedCoordinator

    var body: some View {
        ZStack {
            if let viewModel = coordinator.rootViewModel {
                NavigationStack(path: $coordinator.path) {
                    FeedView(
                        viewModel: viewModel,
                        searchViewModel: viewModel.searchViewModel,
                        shtorkaStateObject: coordinator.shtorkaStateObject
                    )
                    .background(FeedPopGestureEnabler())
                    .navigationDestination(for: FeedDestination.self) { destination($0) }
                }
            }

            sheets
        }
    }

    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.portfolioTokenList) { viewModel in
                MarketsPortfolioTokenListView(viewModel: viewModel)
            }
    }

    @ViewBuilder
    private func destination(_ destination: FeedDestination) -> some View {
        switch destination {
        case .token(let coordinator):
            MarketsTokenDetailsCoordinatorView(coordinator: coordinator)
                .toolbar(.hidden, for: .navigationBar)
        case .portfolioToken(let coordinator):
            TokenDetailsCoordinatorView(coordinator: coordinator)
        }
    }
}
