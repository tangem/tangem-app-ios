//
//  StakingTransactionDataProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Low-level protocol for preparing staking transaction data (for sing and for send)
protocol StakingTransactionDataProvider {
    associatedtype RawTransaction

    func prepareDataForSign(transaction: StakingTransaction) throws -> Data
    func prepareDataForSend(transaction: StakingTransaction, signature: SignatureInfo) throws -> RawTransaction
}
