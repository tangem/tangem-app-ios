//
//  FeedDestinationView.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct FeedDestinationView: View {
    let destination: FeedDestination

    var body: some View {
        switch destination {
        case .token(let coordinator):
            MarketsTokenDetailsCoordinatorView(coordinator: coordinator)
                .background(FeedPopGestureEnabler())
                .toolbar(.hidden, for: .navigationBar)
        case .portfolioToken(let coordinator):
            TokenDetailsCoordinatorView(coordinator: coordinator)
                .background(FeedPopGestureEnabler())
                .toolbar(.hidden, for: .navigationBar)
        case .portfolioTokenList(let viewModel):
            MarketsPortfolioTokenListView(viewModel: viewModel)
        }
    }
}
