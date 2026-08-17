//
//  DogecoinFeeCalculator.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct DogecoinFeeCalculator {
    private let minFee: Decimal
    private let minFeePerByte: Decimal
    private let decimalValue: Decimal

    init(minFee: Decimal, minFeePerByte: Decimal, decimalValue: Decimal) {
        self.minFee = minFee
        self.minFeePerByte = minFeePerByte
        self.decimalValue = decimalValue
    }

    func calculateFeeRates() -> UTXOFee {
        let minimumRate = (minFeePerByte * decimalValue).rounded(roundingMode: .up)

        return UTXOFee(
            slowSatoshiPerByte: minimumRate,
            marketSatoshiPerByte: minimumRate * Constants.marketMultiplier,
            prioritySatoshiPerByte: minimumRate * Constants.priorityMultiplier
        )
    }

    func applyMinimumFees(_ fees: [Fee]) -> [Fee] {
        guard fees.count == Constants.multipliers.count else {
            assertionFailure("Unexpected Dogecoin fee options count")
            return fees
        }

        return zip(fees, Constants.multipliers).map { fee, multiplier in
            let minimumAmount = minFee * multiplier
            guard fee.amount.value < minimumAmount else {
                return fee
            }

            let amount = Amount(with: fee.amount, value: minimumAmount)
            return Fee(amount, parameters: fee.parameters)
        }
    }
}

private extension DogecoinFeeCalculator {
    enum Constants {
        static let marketMultiplier: Decimal = 10
        static let priorityMultiplier: Decimal = 100
        static let multipliers: [Decimal] = [1, marketMultiplier, priorityMultiplier]
    }
}
