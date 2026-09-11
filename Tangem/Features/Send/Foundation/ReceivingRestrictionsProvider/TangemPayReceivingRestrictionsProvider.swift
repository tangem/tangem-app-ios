//
//  TangemPayReceivingRestrictionsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct TangemPayReceivingRestrictionsProvider: ReceivingRestrictionsProvider {
    let userWalletInfo: UserWalletInfo

    func restriction(expectAmount: Decimal) -> ReceivedRestriction? {
        // Not a hard restriction: topping up a wallet with an incomplete backup is confirmed at the `Swap` tap.
        if !userWalletInfo.backupState.isValid {
            return .incompleteBackup(userWalletInfo)
        }

        // TangemPay has no other receiving restrictions.
        return nil
    }
}
