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
        // A card-linked wallet must not receive funds (top-up), even if it was somehow chosen as the swap destination.
        if !userWalletInfo.backupState.isValid {
            return .incompleteBackup
        }

        // TangemPay has no other receiving restrictions.
        return nil
    }
}
