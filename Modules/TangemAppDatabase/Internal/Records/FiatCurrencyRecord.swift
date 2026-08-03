//
//  FiatCurrencyRecord.swift
//  TangemAppDatabase
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

public struct FiatCurrencyRecord {
    public let code: String
    public let name: String
    public let imageURL: String?
    public let precision: Int
    public let updatedAt: Date

    public init(
        code: String,
        name: String,
        imageURL: String?,
        precision: Int,
        updatedAt: Date
    ) {
        self.code = code
        self.name = name
        self.imageURL = imageURL
        self.precision = precision
        self.updatedAt = updatedAt
    }
}

// MARK: - Identifiable protocol conformance

extension FiatCurrencyRecord: Identifiable {
    public var id: String { code }
}

// MARK: - Codable protocol conformance

extension FiatCurrencyRecord: Codable {}

// MARK: - FetchableRecord protocol conformance

extension FiatCurrencyRecord: FetchableRecord {}

// MARK: - TableRecord protocol conformance

extension FiatCurrencyRecord: TableRecord {
    /// - Note: Only columns used twice or more are extracted to this enum.
    public enum Columns {
        public static let code = Column(CodingKeys.code)
    }

    public static let databaseTableName = FiatCurrenciesCacheTable.tableName
}

// MARK: - PersistableRecord protocol conformance

extension FiatCurrencyRecord: PersistableRecord {}
