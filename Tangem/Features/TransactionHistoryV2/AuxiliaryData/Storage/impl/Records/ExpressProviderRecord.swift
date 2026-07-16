//
//  ExpressProviderRecord.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

struct ExpressProviderRecord {
    let id: String
    let name: String
    let type: String
    let exchangeOnlyWithinSingleAddress: Bool
    let imageURL: String?
    let termsOfUse: String?
    let privacyPolicy: String?
    let recommended: Bool?
    /// - Note: Actually a decimal number.
    let slippage: String?
    let updatedAt: Date
}

// MARK: - Columns

extension ExpressProviderRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
    }
}

// MARK: - Identifiable protocol conformance

extension ExpressProviderRecord: Identifiable {}

// MARK: - Codable protocol conformance

extension ExpressProviderRecord: Codable {}

// MARK: - FetchableRecord protocol conformance

extension ExpressProviderRecord: FetchableRecord {}

// MARK: - TableRecord protocol conformance

extension ExpressProviderRecord: TableRecord {
    static let databaseTableName = ExpressProvidersCacheTable.Constants.tableName
}

// MARK: - PersistableRecord protocol conformance

extension ExpressProviderRecord: PersistableRecord {}
