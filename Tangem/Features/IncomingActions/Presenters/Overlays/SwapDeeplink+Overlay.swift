//
//  SwapDeeplink+Overlay.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension SwapDeeplink: DeeplinkOverlayProviding {
    func makeOverlay(in context: DeeplinkOverlayContext) -> DeeplinkOverlayResult? {
        guard let parameters = makeParameters() else {
            return nil
        }

        let coordinator = SendCoordinator(
            dismissAction: { _ in context.dismiss() },
            popToRootAction: { _ in context.dismiss() }
        )
        coordinator.start(with: .init(type: .swap(parameters), source: .main))

        return .ready(context.sheet(AnyView(SendCoordinatorView(coordinator: coordinator))))
    }
}
