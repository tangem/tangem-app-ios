//
//  StakeKitTransaction.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct StakeKitTransaction: Hashable, StakingTransaction {
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
    public let target: String? // validator
    public let solanaBlockhashDate: Date?

    public init(
        id: String,
        amount: Amount,
        fee: Fee,
        unsignedData: String,
        type: TransactionType?,
        status: Status?,
        stepIndex: Int?,
        target: String?,
        solanaBlockhashDate: Date?
    ) {
        self.id = id
        self.amount = amount
        self.fee = fee
        self.unsignedData = unsignedData
        self.type = type
        self.status = status
        self.stepIndex = stepIndex
        self.target = target
        self.solanaBlockhashDate = solanaBlockhashDate
    }
}
