//
//  TokenDeeplink+Overlay.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension TokenDeeplink: DeeplinkOverlayProviding {
    func makeOverlay(in context: DeeplinkOverlayContext) -> DeeplinkOverlayResult? {
        // The wallet the link names has to be on the device; the token itself may still be on its way from
        // the backend, so the link is claimed now and the screen shown when it lands.
        guard !isJointTransaction || FeatureProvider.isAvailable(.jointAccounts), findUserWalletModel() != nil else {
            return nil
        }

        return .whenReady {
            guard let target = await findTarget() else {
                return nil
            }

            target.walletModel.startUpdateTask()

            return context.makeTokenDetailsOverlay(
                walletModel: target.walletModel,
                userWalletModel: target.userWalletModel,
                pendingTransactionDetails: pendingTransactionDetails
            )
        }
    }
}
