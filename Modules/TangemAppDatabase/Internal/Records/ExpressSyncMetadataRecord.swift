//
//  ExpressSyncMetadataRecord.swift
//  TangemAppDatabase
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

public struct ExpressSyncMetadataRecord {
    public let ownerAddress: String
    public let endpointType: String
    public let archiveCursor: String?
    public let deltaCursor: String?
    public let isInitialSyncDone: Bool
    public let lastSyncAt: Date

    public init(
        ownerAddress: String,
        endpointType: String,
        archiveCursor: String?,
        deltaCursor: String?,
        isInitialSyncDone: Bool,
        lastSyncAt: Date
    ) {
        self.ownerAddress = ownerAddress
        self.endpointType = endpointType
        self.archiveCursor = archiveCursor
        self.deltaCursor = deltaCursor
        self.isInitialSyncDone = isInitialSyncDone
        self.lastSyncAt = lastSyncAt
    }
}

// MARK: - Fetching helpers

public extension ExpressSyncMetadataRecord {
    static func filter(ownerAddress: String, endpointType: String) -> QueryInterfaceRequest<Self> {
        return filter(key: [
            ExpressSyncMetadataRecord.Columns.ownerAddress.name: ownerAddress,
            ExpressSyncMetadataRecord.Columns.endpointType.name: endpointType,
        ])
    }

    static func filter(ownerAddress: String) -> QueryInterfaceRequest<Self> {
        return filter { $0.ownerAddress == ownerAddress }
    }
}

// MARK: - Codable protocol conformance

extension ExpressSyncMetadataRecord: Codable {}

// MARK: - FetchableRecord protocol conformance

extension ExpressSyncMetadataRecord: FetchableRecord {}

// MARK: - TableRecord protocol conformance

extension ExpressSyncMetadataRecord: TableRecord {
    /// - Note: Only columns used twice or more are extracted to this enum.
    public enum Columns {
        public static let ownerAddress = Column(CodingKeys.ownerAddress)
        public static let endpointType = Column(CodingKeys.endpointType)
        public static let archiveCursor = Column(CodingKeys.archiveCursor)
        public static let deltaCursor = Column(CodingKeys.deltaCursor)
        public static let isInitialSyncDone = Column(CodingKeys.isInitialSyncDone)
        public static let lastSyncAt = Column(CodingKeys.lastSyncAt)
    }

    public static let databaseTableName = ExpressSyncMetadataTable.tableName
}

// MARK: - PersistableRecord protocol conformance

extension ExpressSyncMetadataRecord: PersistableRecord {}
