//
//  TokenExchangesDeeplink+Overlay.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension TokenExchangesDeeplink: DeeplinkOverlayProviding {
    func makeOverlay(in context: DeeplinkOverlayContext) -> DeeplinkOverlayResult? {
        let viewModel = MarketsTokenDetailsExchangesListViewModel(
            tokenId: tokenId,
            numberOfExchangesListedOn: Constants.skeletonRowCount,
            presentationStyle: .navigationStack,
            exchangesListLoader: MarketsTokenDetailsDataProvider(),
            onBackButtonAction: {}
        )

        return .ready(context.sheet(context.embedInNavigationStack { MarketsTokenDetailsExchangesListView(viewModel: viewModel) }))
    }
}

// MARK: - Constants

private extension TokenExchangesDeeplink {
    enum Constants {
        /// How many rows stand in while the exchanges load: a link, unlike the token details screen, brings no
        /// count of its own.
        static let skeletonRowCount = 5
    }
}
