//
//  StakingTransaction.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public protocol StTransaction {
    associatedtype UnsignedData: Hashable

    var amount: Amount { get }
    var fee: Fee { get }
    var unsignedData: UnsignedData { get }
}

public struct StakeKitTransaction: Hashable, StTransaction {
    public enum Status: String {
        case confirmed = "CONFIRMED" // other statuses are not used, add if necessary
    }

    public enum TransactionType: String {
        case split = "SPLIT" // other types are not used, add if necessary
    }

    public let id: String
    public let amount: Amount
    public let fee: Fee
    public let unsignedData: String
    public let type: TransactionType?
    public let status: Status?
    public let stepIndex: Int?
    public let validator: String?
    public let solanaBlockhashDate: Date?

    public init(id: String, amount: Amount, fee: Fee, unsignedData: String, type: TransactionType?, status: Status?, stepIndex: Int?, validator: String?, solanaBlockhashDate: Date?) {
        self.id = id
        self.amount = amount
        self.fee = fee
        self.unsignedData = unsignedData
        self.type = type
        self.status = status
        self.stepIndex = stepIndex
        self.validator = validator
        self.solanaBlockhashDate = solanaBlockhashDate
    }
}

public struct P2PTransaction: StTransaction {
    public let amount: Amount
    public let fee: Fee
    public let unsignedData: EthereumCompiledTransaction

    public init(amount: Amount, fee: Fee, unsignedData: EthereumCompiledTransaction) {
        self.amount = amount
        self.fee = fee
        self.unsignedData = unsignedData
    }
}

public struct StakeKitTransactionSendResult: Hashable {
    public let transaction: StakeKitTransaction
    public let result: TransactionSendResult
}

public struct StakeKitTransactionParams: TransactionParams {
    public enum Status: String {
        case confirmed = "CONFIRMED" // other statuses are not used, add if necessary
    }

    public enum TransactionType: String {
        case split = "SPLIT" // other types are not used, add if necessary
    }

    public let id: String
    public let type: TransactionType?
    public let status: Status?
    public let stepIndex: Int?
    public let validator: String?
    public let solanaBlockhashDate: Date

    public init(
        id: String,
        type: TransactionType?,
        status: Status?,
        stepIndex: Int,
        validator: String? = nil,
        solanaBlockhashDate: Date
    ) {
        self.id = id
        self.type = type
        self.status = status
        self.stepIndex = stepIndex
        self.validator = validator
        self.solanaBlockhashDate = solanaBlockhashDate
    }
}
