//
//  NEARTransactionParams.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct NEARTransactionParams: TransactionParams {
    let publicKey: Wallet.PublicKey
    let currentNonce: UInt
    let recentBlockHash: String
}
