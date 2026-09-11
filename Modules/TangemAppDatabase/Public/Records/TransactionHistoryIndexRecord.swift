//
//  TransactionHistoryIndexRecord.swift
//  TangemAppDatabase
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

public struct TransactionHistoryIndexRecord {
    public let entityType: String
    public let entityID: String
    public let address: String
    public let network: String
    /// - Note: May have a value of `ExpressConstants.coinContractAddress` for native coins.
    public let contract: String
    public let dateTime: Date

    public init(
        entityType: String,
        entityID: String,
        address: String,
        network: String,
        contract: String,
        dateTime: Date
    ) {
        self.entityType = entityType
        self.entityID = entityID
        self.address = address
        self.network = network
        self.contract = contract
        self.dateTime = dateTime
    }
}

// MARK: - Values

public extension TransactionHistoryIndexRecord {
    enum Values {
        public enum EntityType {
            public static let expressExchange = "expressExchange"
            public static let expressOnramp = "expressOnramp"
        }
    }
}

// MARK: - Fetching helpers

public extension TransactionHistoryIndexRecord {
    /// Re-usable foreign key for both direct and inverse relationships, therefore it is declared here as a static property.
    static let expressEntityForeignKey = ForeignKey([
        TransactionHistoryIndexRecord.Columns.entityID,
    ], to: [
        // Can be dropped since `id` is a primary key of `ExpressExchangeTransactionRecord`, but kept here for clarity
        ExpressExchangeTransactionRecord.Columns.id,
    ])

    /// Re-usable foreign key for both direct and inverse relationships, therefore it is declared here as a static property.
    static let onrampEntityForeignKey = ForeignKey([
        TransactionHistoryIndexRecord.Columns.entityID,
    ], to: [
        // Can be dropped since `id` is a primary key of `ExpressOnrampTransactionRecord`, but kept here for clarity
        ExpressOnrampTransactionRecord.Columns.id,
    ])

    static let expressEntity = belongsTo(
        ExpressExchangeTransactionRecord.self,
        key: "expressEntity",
        using: expressEntityForeignKey
    )

    static let onrampEntity = belongsTo(
        ExpressOnrampTransactionRecord.self,
        key: "onrampEntity",
        using: onrampEntityForeignKey
    )
}

// MARK: - Codable protocol conformance

extension TransactionHistoryIndexRecord: Codable {}

// MARK: - FetchableRecord protocol conformance

extension TransactionHistoryIndexRecord: FetchableRecord {}

// MARK: - TableRecord protocol conformance

extension TransactionHistoryIndexRecord: TableRecord {
    /// - Note: Only columns used twice or more are extracted to this enum.
    public enum Columns {
        public static let entityID = Column(CodingKeys.entityID)
        public static let address = Column(CodingKeys.address)
        public static let network = Column(CodingKeys.network)
        public static let contract = Column(CodingKeys.contract)
        public static let dateTime = Column(CodingKeys.dateTime)
    }

    public static let databaseTableName = TransactionHistoryIndexTable.tableName
}

// MARK: - PersistableRecord protocol conformance

extension TransactionHistoryIndexRecord: PersistableRecord {}
