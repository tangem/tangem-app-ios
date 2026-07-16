//
//  ExpressOnrampTransactionRecord.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

struct ExpressOnrampTransactionRecord {
    let id: String
    let ownerAddress: String
    let providerID: String
    let payOutAddress: String?
    let status: String
    let externalTxID: String?
    let externalTxURL: String?
    let payOutHash: String?
    let fromCurrency: String
    /// Actually a decimal number.
    let fromAmount: String
    let fromDecimals: Int?
    let toContract: String?
    let toNetwork: String
    /// Actually a decimal number.
    let toAmount: String
    let toDecimals: Int
    /// Actually a decimal number.
    let toActualAmount: String?
    let failReason: String?
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Identifiable protocol conformance

extension ExpressOnrampTransactionRecord: Identifiable {}

// MARK: - Codable protocol conformance

extension ExpressOnrampTransactionRecord: Codable {}

// MARK: - FetchableRecord protocol conformance

extension ExpressOnrampTransactionRecord: FetchableRecord {}

// MARK: - TableRecord protocol conformance

extension ExpressOnrampTransactionRecord: TableRecord {
    static let databaseTableName = ExpressOnrampTransactionsTable.Constants.tableName
}

// MARK: - PersistableRecord protocol conformance

extension ExpressOnrampTransactionRecord: PersistableRecord {}
