//
//  PendingTransactionRecord.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct PendingTransactionRecord {
    public enum TransactionType {
        case transfer
        case operation
        case stake(target: String?)
    }

    public let hash: String
    public let source: String
    public let destination: String
    public let amount: Amount
    public let fee: Fee
    public let date: Date
    public let isIncoming: Bool
    public let networkProviderType: NetworkProviderType?
    public let transactionType: TransactionType
    public let transactionParams: TransactionParams?

    public var isDummy: Bool {
        hash == .unknown || source == .unknown || destination == .unknown
    }

    public init(
        hash: String,
        source: String,
        destination: String,
        amount: Amount,
        fee: Fee,
        date: Date,
        isIncoming: Bool,
        networkProviderType: NetworkProviderType? = nil,
        transactionType: TransactionType,
        transactionParams: TransactionParams? = nil
    ) {
        self.hash = hash
        self.source = source
        self.destination = destination
        self.amount = amount
        self.fee = fee
        self.date = date
        self.isIncoming = isIncoming
        self.networkProviderType = networkProviderType
        self.transactionType = transactionType
        self.transactionParams = transactionParams
    }
}

extension PendingTransactionRecord: Hashable, Equatable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(hash)
    }

    public static func == (lhs: PendingTransactionRecord, rhs: PendingTransactionRecord) -> Bool {
        lhs.hash == rhs.hash
    }
}
