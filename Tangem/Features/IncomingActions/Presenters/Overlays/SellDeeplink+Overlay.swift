//
//  SellDeeplink+Overlay.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension SellDeeplink: DeeplinkOverlayProviding {
    func makeOverlay(in context: DeeplinkOverlayContext) -> DeeplinkOverlayResult? {
        guard let userWalletModel = findUserWalletModel() else {
            return nil
        }

        let coordinator = context.coordinatorFactory.makeSellCoordinator(
            userWalletModel: userWalletModel,
            dismissAction: { _ in context.dismiss() }
        )

        coordinator.start(with: .init(tokenSelectorViewModel: .deeplinkSell()))

        return .ready(context.sheet(AnyView(ActionButtonsSellCoordinatorView(coordinator: coordinator))))
    }
}
