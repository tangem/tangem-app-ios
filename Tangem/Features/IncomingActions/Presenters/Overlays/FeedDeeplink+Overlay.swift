//
//  FeedDeeplink+Overlay.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension FeedDeeplink: DeeplinkOverlayProviding {
    func makeOverlay(in context: DeeplinkOverlayContext) -> DeeplinkOverlayResult? {
        let coordinator = FeedCoordinator(
            dismissAction: { context.dismiss() },
            popToRootAction: { _ in context.dismiss() }
        )

        // No host: the main screen is behind whatever this is shown over, so anything pushed onto it would come
        // up underneath. The feed leaves out what it would have handed over and opens on its own.
        coordinator.start(with: .init(container: StandaloneFeedContainer(), selection: makeSelection()))

        return .ready(context.sheet(FeedCoordinatorView(coordinator: coordinator)))
    }
}
