//
//  ExpressProviderRecord.swift
//  TangemAppDatabase
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

public struct ExpressProviderRecord {
    public let id: String
    public let name: String
    public let type: String
    public let exchangeOnlyWithinSingleAddress: Bool
    public let imageURL: String?
    public let termsOfUse: String?
    public let privacyPolicy: String?
    public let recommended: Bool?
    /// - Note: Actually a decimal number.
    public let slippage: String?
    public let updatedAt: Date

    public init(
        id: String,
        name: String,
        type: String,
        exchangeOnlyWithinSingleAddress: Bool,
        imageURL: String?,
        termsOfUse: String?,
        privacyPolicy: String?,
        recommended: Bool?,
        slippage: String?,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.exchangeOnlyWithinSingleAddress = exchangeOnlyWithinSingleAddress
        self.imageURL = imageURL
        self.termsOfUse = termsOfUse
        self.privacyPolicy = privacyPolicy
        self.recommended = recommended
        self.slippage = slippage
        self.updatedAt = updatedAt
    }
}

// MARK: - Values

extension ExpressProviderRecord {
    enum Values {
        /// Raw `type` column values per Express branch, mirroring `ExpressBranch.supportedProviderTypes`, used in filters.
        /// Copy-pasted here because the DB layer can't depend on `TangemExpress` target and therefore can't use `ExpressBranch` type.
        enum ProviderType {
            static let swap = [
                "dex",
                "cex",
                "dex-bridge",
            ]

            static let onramp = [
                "onramp",
            ]
        }
    }
}

// MARK: - Codable protocol conformance

extension ExpressProviderRecord: Codable {}

// MARK: - FetchableRecord protocol conformance

extension ExpressProviderRecord: FetchableRecord {}

// MARK: - TableRecord protocol conformance

extension ExpressProviderRecord: TableRecord {
    /// - Note: Only columns used twice or more are extracted to this enum.
    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let type = Column(CodingKeys.type)
    }

    public static let databaseTableName = ExpressProvidersCacheTable.tableName
}

// MARK: - PersistableRecord protocol conformance

extension ExpressProviderRecord: PersistableRecord {}
