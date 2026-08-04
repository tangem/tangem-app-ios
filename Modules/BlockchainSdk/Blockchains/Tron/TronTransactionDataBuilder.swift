//
//  TronTransactionDataBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol TronTransactionDataBuilder {
    /// Returns the full TRC20 `approve(address,uint256)` calldata: selector + padded spender + padded amount.
    func buildForApprove(spender: String, amount: Amount) throws -> Data
}
