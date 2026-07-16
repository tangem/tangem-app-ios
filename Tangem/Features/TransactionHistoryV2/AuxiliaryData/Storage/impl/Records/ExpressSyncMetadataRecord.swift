//
//  ExpressSyncMetadataRecord.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

struct ExpressSyncMetadataRecord {
    let ownerAddress: String
    let endpointType: String
    let archiveCursor: String?
    let deltaCursor: String?
    let isInitialSyncDone: Bool
    let lastSyncAt: Date
}

// MARK: - Codable protocol conformance

extension ExpressSyncMetadataRecord: Codable {}

// MARK: - FetchableRecord protocol conformance

extension ExpressSyncMetadataRecord: FetchableRecord {}

// MARK: - TableRecord protocol conformance

extension ExpressSyncMetadataRecord: TableRecord {
    static let databaseTableName = ExpressSyncMetadataTable.Constants.tableName
}

// MARK: - PersistableRecord protocol conformance

extension ExpressSyncMetadataRecord: PersistableRecord {}
