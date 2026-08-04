//
//  TronTransactionParams.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct TronTransactionParams: TransactionParams {
    /// In sun.
    public static let defaultSmartContractFeeLimit: Int64 = 100_000_000

    public let transactionType: TransactionType
    /// Written to the transaction-level `raw.data` field (e.g. a THORChain swap memo).
    public let memo: String?

    public init(transactionType: TransactionType, memo: String? = nil) {
        self.transactionType = transactionType
        self.memo = memo
    }
}

public extension TronTransactionParams {
    enum TransactionType {
        case transfer
        /// `feeLimit` is in sun; `nil` falls back to `defaultSmartContractFeeLimit`.
        case contractCall(callData: Data, feeLimit: Int64?)
    }
}
