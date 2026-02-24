//
//  ReceivingRestrictionsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol ReceivingRestrictionsProvider {
    func restriction(expectAmount: Decimal) -> ReceivedRestriction?
}

enum ReceivedRestriction {
    case notEnoughReceivedAmount(minAmount: Decimal)
}

struct CommonReceivingRestrictionsProvider: ReceivingRestrictionsProvider {
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
