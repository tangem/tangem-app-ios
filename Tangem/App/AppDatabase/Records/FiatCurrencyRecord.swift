//
//  FiatCurrencyRecord.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

struct FiatCurrencyRecord {
    let code: String
    let name: String
    let imageURL: String?
    let precision: Int
}

// MARK: - Columns

extension FiatCurrencyRecord {
    /// - Note: Only columns used twice or more are extracted to this enum.
    enum Columns {
        static let code = Column(CodingKeys.code)
    }
}

// MARK: - Identifiable protocol conformance

extension FiatCurrencyRecord: Identifiable {
    var id: String { code }
}

// MARK: - Codable protocol conformance

extension FiatCurrencyRecord: Codable {}

// MARK: - FetchableRecord protocol conformance

extension FiatCurrencyRecord: FetchableRecord {}

// MARK: - TableRecord protocol conformance

extension FiatCurrencyRecord: TableRecord {
    static let databaseTableName = FiatCurrenciesCacheTable.tableName
}

// MARK: - PersistableRecord protocol conformance

extension FiatCurrencyRecord: PersistableRecord {}
