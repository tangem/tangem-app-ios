//
//  StakingDeeplink+Overlay.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension StakingDeeplink: DeeplinkOverlayProviding {
    func makeOverlay(in context: DeeplinkOverlayContext) -> DeeplinkOverlayResult? {
        guard let options = makeOptions() else {
            return nil
        }

        let coordinator = context.coordinatorFactory.makeStakingCoordinator(
            dismissAction: { context.dismiss() },
            popToRootAction: { _ in }
        )
        coordinator.start(with: options)

        return .ready(context.sheet(context.embedInNavigationStack { StakingDetailsCoordinatorView(coordinator: coordinator) }))
    }
}
