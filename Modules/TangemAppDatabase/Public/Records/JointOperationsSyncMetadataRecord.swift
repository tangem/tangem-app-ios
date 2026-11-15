//
//  JointOperationsSyncMetadataRecord.swift
//  TangemAppDatabase
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

public struct JointOperationsSyncMetadataRecord {
    public let walletID: String
    public let archiveCursor: String?
    public let deltaCursor: String?
    public let isInitialSyncDone: Bool
    public let lastSyncAt: Date

    public init(
        walletID: String,
        archiveCursor: String?,
        deltaCursor: String?,
        isInitialSyncDone: Bool,
        lastSyncAt: Date
    ) {
        self.walletID = walletID
        self.archiveCursor = archiveCursor
        self.deltaCursor = deltaCursor
        self.isInitialSyncDone = isInitialSyncDone
        self.lastSyncAt = lastSyncAt
    }
}

// MARK: - Fetching helpers

public extension JointOperationsSyncMetadataRecord {
    static func filter(walletID: String) -> QueryInterfaceRequest<Self> {
        return filter { $0.walletID == walletID }
    }
}

// MARK: - Codable protocol conformance

extension JointOperationsSyncMetadataRecord: Codable {}

// MARK: - FetchableRecord protocol conformance

extension JointOperationsSyncMetadataRecord: FetchableRecord {}

// MARK: - TableRecord protocol conformance

extension JointOperationsSyncMetadataRecord: TableRecord {
    public enum Columns {
        public static let walletID = Column(CodingKeys.walletID)
        public static let archiveCursor = Column(CodingKeys.archiveCursor)
        public static let deltaCursor = Column(CodingKeys.deltaCursor)
        public static let isInitialSyncDone = Column(CodingKeys.isInitialSyncDone)
        public static let lastSyncAt = Column(CodingKeys.lastSyncAt)
    }

    public static let databaseTableName = JointOperationsSyncMetadataTable.tableName
}

// MARK: - PersistableRecord protocol conformance

extension JointOperationsSyncMetadataRecord: PersistableRecord {}
