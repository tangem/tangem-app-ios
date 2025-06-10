//
//  TONTransactionInput.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct TONTransactionInput {
    let amount: Amount
    let destination: String
    let expireAt: UInt32
    let jettonWalletAddress: String?
    let params: TONTransactionParams?
}
