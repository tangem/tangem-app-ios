//
//  AssetRequirementsCondition.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// Represents a particular action that must be performed to fulfill the requirements of a given kind of 'asset'.
/// An 'asset' can be either a coin or token.
public enum AssetRequirementsCondition {
    /// The exact value of the fee for this type of condition is stored in `feeAmount`.
    case paidTransactionWithFee(blockchain: Blockchain, transactionAmount: Amount?, feeAmount: Amount?)
    @available(*, unavailable, message: "Token trust lines support not implemented yet")
    case minimumBalanceChange(newMinimumBalance: Amount)
}
