//
//  TransactionHistoryIndexRecord.swift
//  TangemAppDatabase
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

struct TransactionHistoryIndexRecord {
    let entityType: String
    let entityID: String
    let ownerAddress: String
    let dateTime: Date
}

// MARK: - Columns

extension TransactionHistoryIndexRecord {
    /// - Note: Only columns used twice or more are extracted to this enum.
    enum Columns {
        static let entityID = Column(CodingKeys.entityID)
    }
}

// MARK: - Codable protocol conformance

extension TransactionHistoryIndexRecord: Codable {}

// MARK: - FetchableRecord protocol conformance

extension TransactionHistoryIndexRecord: FetchableRecord {}

// MARK: - TableRecord protocol conformance

extension TransactionHistoryIndexRecord: TableRecord {
    static let databaseTableName = TransactionHistoryIndexTable.tableName

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

// MARK: - PersistableRecord protocol conformance

extension TransactionHistoryIndexRecord: PersistableRecord {}
