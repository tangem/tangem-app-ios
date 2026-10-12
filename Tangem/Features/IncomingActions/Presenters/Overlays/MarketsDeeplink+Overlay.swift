//
//  MarketsDeeplink+Overlay.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension MarketsDeeplink: DeeplinkOverlayProviding {
    func makeOverlay(in context: DeeplinkOverlayContext) -> DeeplinkOverlayResult? {
        let coordinator = context.coordinatorFactory.makeMarketsSearchCoordinator(dismissAction: { context.dismiss() })

        coordinator.start(
            with: .init(
                initialOrderType: filter.order,
                initialIntervalType: filter.interval,
                quotesRepositoryUpdateHelper: CommonMarketsQuotesUpdateHelper(),
                leadingButton: .close
            )
        )

        return .ready(context.sheet(context.embedInNavigationStack { MarketsSearchCoordinatorView(coordinator: coordinator) }))
    }
}
