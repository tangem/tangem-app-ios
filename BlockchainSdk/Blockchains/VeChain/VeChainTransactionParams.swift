//
//  VeChainTransactionParams.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct VeChainTransactionParams: TransactionParams {
    let publicKey: Wallet.PublicKey
    let lastBlockInfo: VeChainBlockInfo
    let nonce: UInt
}
