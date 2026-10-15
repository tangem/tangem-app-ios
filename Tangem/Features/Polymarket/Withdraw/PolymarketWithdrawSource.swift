//
//  PolymarketWithdrawSource.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct PolymarketWithdrawSource {
    let accountModel: any PolymarketAccountModel
    let depositWalletAddress: String
    let transactionService: PolymarketWithdrawTransactionService
    let signer: TangemSigner
    let minimumUSD: Decimal
}
