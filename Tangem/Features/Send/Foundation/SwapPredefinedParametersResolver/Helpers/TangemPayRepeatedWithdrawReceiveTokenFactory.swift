//
//  TangemPayRepeatedWithdrawReceiveTokenFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct TangemPayRepeatedWithdrawReceiveTokenFactory {
    let target: TangemPayRecentOperationTarget

    func makeReceiveToken() -> SendReceiveToken? {
        let availability = TokenActionAvailabilityProvider(
            userWalletInfo: target.receiveUserWalletInfo,
            walletModel: target.receiveWalletModel
        ).swapReceiveAvailability()

        guard SwapReceivePreselectionEligibility.canBecomeReceive(for: availability) else {
            return nil
        }

        return WalletModelSendTokenFactory(userWalletInfo: target.receiveUserWalletInfo, walletModel: target.receiveWalletModel, operationType: .swap).makeReceiveToken()
    }
}
