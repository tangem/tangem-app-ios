//
//  ExpressExchangeTransactionRecord.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

struct ExpressExchangeTransactionRecord {
    let id: String
    let ownerAddress: String
    let providerID: String
    let fromAddress: String?
    let payInAddress: String?
    let payOutAddress: String?
    let status: String
    let externalTxID: String?
    let externalTxURL: String?
    let payInHash: String?
    let payOutHash: String?
    let fromContract: String?
    let fromNetwork: String
    /// Actually a decimal number.
    let fromAmount: String
    let fromDecimals: Int
    let toContract: String?
    let toNetwork: String
    /// Actually a decimal number.
    let toAmount: String
    let toDecimals: Int
    /// Actually a decimal number.
    let toActualAmount: String?
    let failReason: String?
    let refundAddress: String?
    let refundNetwork: String?
    let refundContractAddress: String?
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Identifiable protocol conformance

extension ExpressExchangeTransactionRecord: Identifiable {}

// MARK: - Codable protocol conformance

extension ExpressExchangeTransactionRecord: Codable {}

// MARK: - FetchableRecord protocol conformance

extension ExpressExchangeTransactionRecord: FetchableRecord {}

// MARK: - TableRecord protocol conformance

extension ExpressExchangeTransactionRecord: TableRecord {
    static let databaseTableName = ExpressExchangeTransactionsTable.Constants.tableName
}

// MARK: - PersistableRecord protocol conformance

extension ExpressExchangeTransactionRecord: PersistableRecord {}
