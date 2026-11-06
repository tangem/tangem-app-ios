//
//  YieldGaslessEnterAmountCalculator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import BlockchainSdk
import TangemFoundation

struct YieldGaslessEnterAmountCalculator {
    func enterAmount(balance: Decimal, fee: BSDKFee, token: Token) -> BigUInt? {
        let balanceInTokenUnits = (balance * token.decimalValue).rounded(roundingMode: .down)
        let feeInTokenUnits = (fee.amount.value * token.decimalValue).rounded(roundingMode: .up)

        guard balanceInTokenUnits > feeInTokenUnits else {
            return nil
        }

        return BigUInt(decimal: balanceInTokenUnits - feeInTokenUnits)
    }

    func isPaidWithSuppliedToken(fee: BSDKFee, token: Token) -> Bool {
        fee.amount.type.token == token
    }
}
