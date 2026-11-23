//
//  GaslessMaxTokenFeeCalculator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import TangemFoundation

enum GaslessMaxTokenFeeCalculator {
    static func maxTokenFee(feeAmount: Decimal, decimalValue: Decimal, keepsYieldWithdrawReserve: Bool) -> BigUInt? {
        let feeInTokenUnits = (feeAmount * decimalValue).rounded(roundingMode: .up)
        let canKeepReserve = keepsYieldWithdrawReserve && feeInTokenUnits > yieldWithdrawRoundingReserve
        let reserve = canKeepReserve ? yieldWithdrawRoundingReserve : 0

        return BigUInt(decimal: feeInTokenUnits - reserve)
    }
}

private extension GaslessMaxTokenFeeCalculator {
    static let yieldWithdrawRoundingReserve: Decimal = 5
}
