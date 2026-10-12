//
//  BuyDeeplink+Overlay.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension BuyDeeplink: DeeplinkOverlayProviding {
    func makeOverlay(in context: DeeplinkOverlayContext) -> DeeplinkOverlayResult? {
        guard let userWalletModel = findUserWalletModel() else {
            return nil
        }

        let coordinator = context.coordinatorFactory.makeBuyCoordinator(dismissAction: { _ in context.dismiss() })

        coordinator.start(
            with: .init(
                userWalletModels: [userWalletModel],
                preferredWalletId: ActionButtonsBuyPreselection.userWalletId(for: userWalletModel)
            )
        )

        return .ready(context.sheet(AnyView(ActionButtonsBuyCoordinatorView(coordinator: coordinator))))
    }
}
