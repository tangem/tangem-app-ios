//
//  GetAmountMethod.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct GetAmountMethod: SmartContractMethod {
    let amountType: AmountType

    var methodId: String {
        SmartContractMethodIdCreator().createIdForMethod(with: amountType.rawValue)
    }

    var data: Data {
        let prefixData = Data(hexString: methodId)
        return prefixData.trailingZeroPadding(toLength: 32)
    }
}

extension GetAmountMethod {
    enum AmountType: String {
        case verifiedBalance = "verifiedBalance()"
        case availableForPayment = "availableForPayment()"
        case blocked = "blockedAmount()"
        case debt = "debtAmount()"
        case limits = "limits()"
        case cards = "cards()"
        case activeCardAddresses = "activeCardAddresses()"
    }
}
