//
//  CryptoCurrencyRecord.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

struct CryptoCurrencyRecord {
    let id: String?
    let networkID: String
    let name: String
    let symbol: String
    let contractAddress: String
    let decimalCount: Int
}

// MARK: - Codable protocol conformance

extension CryptoCurrencyRecord: Codable {}

// MARK: - FetchableRecord protocol conformance

extension CryptoCurrencyRecord: FetchableRecord {}

// MARK: - TableRecord protocol conformance

extension CryptoCurrencyRecord: TableRecord {
    static let databaseTableName = CryptoCurrenciesCacheTable.Constants.tableName
}

// MARK: - PersistableRecord protocol conformance

extension CryptoCurrencyRecord: PersistableRecord {}
