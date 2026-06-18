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
        // A card-linked wallet must not receive funds (top-up), even if it was somehow chosen as the swap destination.
        if !userWalletInfo.backupState.isValid {
            return .incompleteBackup
        }

        switch walletModel.state {
        case .noAccount(_, let amountToCreateAccount) where expectAmount < amountToCreateAccount:
            return .notEnoughReceivedAmount(minAmount: amountToCreateAccount)
        default:
            return .none
        }
    }
}
