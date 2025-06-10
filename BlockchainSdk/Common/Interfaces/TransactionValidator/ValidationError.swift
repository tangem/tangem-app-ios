//
//  ValidationError.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

public enum ValidationError: Hashable, LocalizedError {
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

    case destinationMemoRequired

    public var errorDescription: String? {
        switch self {
        case .balanceNotFound,
             .cardanoInsufficientBalanceToSendToken,
             .remainingAmountIsLessThanRentExemption,
             .cardanoHasTokens,
             .amountExceedsBalance,
             .dustAmount,
             .dustChange,
             .minimumBalance,
             .feeExceedsBalance,
             .feeExceedsMaxFeeResource,
             .invalidAmount,
             .amountExceedsFeeResourceCapacity,
             .totalExceedsBalance,
             .invalidFee,
             .maximumUTXO,
             .reserve,
             .insufficientFeeResource,
             .minimumRestrictAmount,
             .destinationMemoRequired:
            assertionFailure("Potential text loss detected. Please ensure all UI strings and localizations are preserved.")
            return .none // displayed as notification
        }
    }
}
