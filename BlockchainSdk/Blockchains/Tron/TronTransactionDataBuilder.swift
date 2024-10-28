//
//  TronTransactionDataBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol TronTransactionDataBuilder {
    func buildForApprove(spender: String, amount: Amount) throws -> Data
}
