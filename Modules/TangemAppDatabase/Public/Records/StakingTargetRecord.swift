//
//  StakingTargetRecord.swift
//  TangemAppDatabase
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

public struct StakingTargetRecord {
    public let networkID: String
    public let address: String
    public let name: String
    public let updatedAt: Date

    public init(
        networkID: String,
        address: String,
        name: String,
        updatedAt: Date
    ) {
        self.networkID = networkID
        self.address = address
        self.name = name
        self.updatedAt = updatedAt
    }
}

// MARK: - Codable protocol conformance

extension StakingTargetRecord: Codable {}

// MARK: - FetchableRecord protocol conformance

extension StakingTargetRecord: FetchableRecord {}

// MARK: - TableRecord protocol conformance

extension StakingTargetRecord: TableRecord {
    public static let databaseTableName = StakingTargetsCacheTable.tableName
}

// MARK: - PersistableRecord protocol conformance

extension StakingTargetRecord: PersistableRecord {}
