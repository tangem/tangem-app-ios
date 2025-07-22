//
//  ValidationError.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum ValidationError: Error, Equatable {
    case balanceNotFound
    case invalidAmount
    case amountExceedsBalance
    case invalidFee
    case feeExceedsBalance
    case totalExceedsBalance

    case dustAmount(minimumAmount: Amount)
    case dustChange(minimumAmount: Amount)
    case minimumBalance(minimumBalance: Amount)
    case maximumUTXO(blockchainName: String, newAmount: Amount, maxUtxo: Int)
    case reserve(amount: Amount)

    case minimumRestrictAmount(amount: Amount)

    case cardanoHasTokens(minimumAmount: Amount)
    case cardanoInsufficientBalanceToSendToken

    case insufficientFeeResource(type: FeeResourceType, current: Decimal, max: Decimal)
    case amountExceedsFeeResourceCapacity(type: FeeResourceType, availableAmount: Decimal)
    case feeExceedsMaxFeeResource
    case remainingAmountIsLessThanRentExemption(amount: Amount)
    case sendingAmountIsLessThanRentExemption(amount: Amount)

    case destinationMemoRequired
}
