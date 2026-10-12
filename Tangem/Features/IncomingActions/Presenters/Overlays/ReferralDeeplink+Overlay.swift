//
//  ReferralDeeplink+Overlay.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension ReferralDeeplink: DeeplinkOverlayProviding {
    func makeOverlay(in context: DeeplinkOverlayContext) -> DeeplinkOverlayResult? {
        guard let input = makeInput() else {
            return nil
        }

        let coordinator = context.coordinatorFactory.makeReferralCoordinator(dismissAction: { context.dismiss() })
        coordinator.start(with: .init(input: input))

        return .ready(context.sheet(context.embedInNavigationStack { ReferralCoordinatorView(coordinator: coordinator) }))
    }
}
