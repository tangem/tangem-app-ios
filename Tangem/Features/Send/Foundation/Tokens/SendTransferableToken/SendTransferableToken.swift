//
//  SendTransferableToken.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

typealias SendStakingableToken = SendTransferableToken

protocol SendTransferableToken: SendSourceToken {
    var transactionValidator: SendTransactionValidator { get }
    var transactionCreator: SendTransactionCreator { get }
    var tokenFeeProvidersManager: TokenFeeProvidersManager { get }
}
