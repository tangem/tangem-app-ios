//
//  WalletModelReceivingRestrictionsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct WalletModelReceivingRestrictionsProvider: ReceivingRestrictionsProvider {
    let walletModel: any WalletModel

    func restriction(expectAmount: Decimal) -> ReceivedRestriction? {
        switch walletModel.state {
        case .noAccount(_, let amountToCreateAccount) where expectAmount < amountToCreateAccount:
            return .notEnoughReceivedAmount(minAmount: amountToCreateAccount)
        default:
            return .none
        }
    }
}
