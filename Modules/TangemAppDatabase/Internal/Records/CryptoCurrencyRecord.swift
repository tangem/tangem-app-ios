//
//  CryptoCurrencyRecord.swift
//  TangemAppDatabase
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

public struct CryptoCurrencyRecord {
    public let id: String?
    public let networkID: String
    public let name: String
    public let symbol: String
    /// - Note: May have a value of `ExpressConstants.coinContractAddress` for native coins.
    public let contractAddress: String
    public let decimalCount: Int
    public let updatedAt: Date

    public init(
        id: String?,
        networkID: String,
        name: String,
        symbol: String,
        contractAddress: String,
        decimalCount: Int,
        updatedAt: Date
    ) {
        self.id = id
        self.networkID = networkID
        self.name = name
        self.symbol = symbol
        self.contractAddress = contractAddress
        self.decimalCount = decimalCount
        self.updatedAt = updatedAt
    }
}

// MARK: - Codable protocol conformance

extension CryptoCurrencyRecord: Codable {}

// MARK: - FetchableRecord protocol conformance

extension CryptoCurrencyRecord: FetchableRecord {}

// MARK: - TableRecord protocol conformance

extension CryptoCurrencyRecord: TableRecord {
    /// - Note: Only columns used twice or more are extracted to this enum.
    public enum Columns {
        public static let networkID = Column(CodingKeys.networkID)
        public static let contractAddress = Column(CodingKeys.contractAddress)
    }

    public static let databaseTableName = CryptoCurrenciesCacheTable.tableName
}

// MARK: - PersistableRecord protocol conformance

extension CryptoCurrencyRecord: PersistableRecord {}
