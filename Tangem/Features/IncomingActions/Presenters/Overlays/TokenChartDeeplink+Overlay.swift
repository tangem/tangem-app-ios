//
//  TokenChartDeeplink+Overlay.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension TokenChartDeeplink: DeeplinkOverlayProviding {
    func makeOverlay(in context: DeeplinkOverlayContext) -> DeeplinkOverlayResult? {
        let coordinator = context.coordinatorFactory.makeMarketsTokenDetailsCoordinator()
        coordinator.start(with: .tokenChartDeeplink(tokenId: tokenId))

        return .ready(context.sheet(context.embedInNavigationStack { MarketsTokenDetailsCoordinatorView(coordinator: coordinator) }))
    }
}
