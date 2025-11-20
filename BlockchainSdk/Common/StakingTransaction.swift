//
//  StakingTransaction.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public struct StakingTransaction {
    public let id: String
    let amount: Amount
    let fee: Fee
    let unsignedData: any UnsignedTransactionData
    public let params: (any TransactionParams)?

    public init(
        id: String,
        amount: Amount,
        fee: Fee,
        unsignedData: any UnsignedTransactionData,
        params: (any TransactionParams)?
    ) {
        self.id = id
        self.amount = amount
        self.fee = fee
        self.unsignedData = unsignedData
        self.params = params
    }
}

extension StakingTransaction: Equatable {
    public static func == (lhs: StakingTransaction, rhs: StakingTransaction) -> Bool {
        lhs.unsignedData.hashValue == rhs.unsignedData.hashValue
    }
}

extension StakingTransaction: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(unsignedData)
    }
}

public struct StakeKitTransactionSendResult: Hashable {
    public let transaction: StakingTransaction
    public let result: TransactionSendResult
}

public struct StakeKitTransactionParams: TransactionParams {
    public enum Status: String {
        case confirmed = "CONFIRMED" // other statuses are not used, add if necessary
    }

    public enum TransactionType: String {
        case split = "SPLIT" // other types are not used, add if necessary
    }

    public let type: TransactionType?
    public let status: Status?
    public let stepIndex: Int?
    public let validator: String?
    let solanaBlockhashDate: Date

    public init(
        type: TransactionType?,
        status: Status?,
        stepIndex: Int,
        validator: String? = nil,
        solanaBlockhashDate: Date
    ) {
        self.type = type
        self.status = status
        self.stepIndex = stepIndex
        self.validator = validator
        self.solanaBlockhashDate = solanaBlockhashDate
    }
}
