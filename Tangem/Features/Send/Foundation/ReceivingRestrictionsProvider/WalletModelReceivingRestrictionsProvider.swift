//
//  WalletModelReceivingRestrictionsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct WalletModelReceivingRestrictionsProvider: ReceivingRestrictionsProvider {
    let userWalletInfo: UserWalletInfo
    let walletModel: any WalletModel

    func restriction(expectAmount: Decimal) -> ReceivedRestriction? {
        // Not a hard restriction: topping up a wallet with an incomplete backup is confirmed at the `Swap` tap.
        if !userWalletInfo.backupState.isValid {
            return .incompleteBackup(userWalletInfo)
        }

        switch walletModel.state {
        case .noAccount(_, let amountToCreateAccount) where expectAmount < amountToCreateAccount:
            return .notEnoughReceivedAmount(minAmount: amountToCreateAccount)
        default:
            return .none
        }
    }
}
