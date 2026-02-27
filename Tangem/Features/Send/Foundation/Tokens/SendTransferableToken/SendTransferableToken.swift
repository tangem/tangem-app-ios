//
//  SendTransferableToken.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

typealias SendStakingableToken = SendTransferableToken

protocol SendTransferableToken: SendSourceToken {
    var transactionValidator: TransactionValidator { get }
    var transactionCreator: TransactionCreator { get }
    var tokenFeeProvidersManager: TokenFeeProvidersManager { get }
}
