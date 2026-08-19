//
//  CommonTransactionHistorySyncMetadataStorage.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemAppDatabase

struct CommonTransactionHistorySyncMetadataStorage {
    @Injected(\.appDatabase) private var appDatabase: AppDatabase

    private let ownerAddress: String

    init(ownerAddress: String) {
        self.ownerAddress = ownerAddress
    }
}

// MARK: - TransactionHistorySyncMetadataStorage protocol conformance

extension CommonTransactionHistorySyncMetadataStorage: TransactionHistorySyncMetadataStorage {
    func initialSyncCursor(for branch: ExpressBranch) async throws -> Any? {
        return try await appDatabase.databaseHandle.read { database in
            try ExpressSyncMetadataRecord
                .filter(ownerAddress: ownerAddress, endpointType: branch.endpointType)
                .fetchOne(database)?
                .archiveCursor
        }
    }

    func setInitialSyncCursor(_ cursor: Any?, for branch: ExpressBranch) async throws {
        try await appDatabase.databaseHandle.write { database in
            let endpointType = branch.endpointType
            let lastSyncAt = Date()
            let archiveCursor = cursor as? String // [REDACTED_TODO_COMMENT]

            let updatedRecordsCount = try ExpressSyncMetadataRecord
                .filter(ownerAddress: ownerAddress, endpointType: endpointType)
                .updateAll(database) { record in
                    [
                        record.archiveCursor.set(to: archiveCursor),
                        record.lastSyncAt.set(to: lastSyncAt),
                    ]
                }

            // Upsert was performed, early exit
            if updatedRecordsCount > 0 {
                return
            }

            try ExpressSyncMetadataRecord(
                ownerAddress: ownerAddress,
                endpointType: endpointType,
                archiveCursor: archiveCursor,
                deltaCursor: nil,
                isInitialSyncDone: false,
                lastSyncAt: lastSyncAt
            ).insert(database)
        }
    }

    func deltaSyncCursor(for branch: ExpressBranch) async throws -> Any? {
        return try await appDatabase.databaseHandle.read { database in
            try ExpressSyncMetadataRecord
                .filter(ownerAddress: ownerAddress, endpointType: branch.endpointType)
                .fetchOne(database)?
                .deltaCursor
        }
    }

    func setDeltaSyncCursor(_ cursor: Any?, for branch: ExpressBranch) async throws {
        try await appDatabase.databaseHandle.write { database in
            let endpointType = branch.endpointType
            let lastSyncAt = Date()
            let deltaCursor = cursor as? String // [REDACTED_TODO_COMMENT]

            let updatedRecordsCount = try ExpressSyncMetadataRecord
                .filter(ownerAddress: ownerAddress, endpointType: endpointType)
                .updateAll(database) { record in
                    [
                        record.deltaCursor.set(to: deltaCursor),
                        record.lastSyncAt.set(to: lastSyncAt),
                    ]
                }

            // Upsert was performed, early exit
            if updatedRecordsCount > 0 {
                return
            }

            try ExpressSyncMetadataRecord(
                ownerAddress: ownerAddress,
                endpointType: endpointType,
                archiveCursor: nil,
                deltaCursor: deltaCursor,
                isInitialSyncDone: false,
                lastSyncAt: lastSyncAt
            ).insert(database)
        }
    }

    func isInitialSyncDone() async throws -> Bool {
        return try await appDatabase.databaseHandle.read { database in
            try ExpressSyncMetadataRecord
                // There is no separate sync completion tracking for different branches, so any record will do
                .filter(ownerAddress: ownerAddress)
                .filter { $0.isInitialSyncDone }
                .fetchCount(database) > 0
        }
    }

    func setIsInitialSyncDone(_ isDone: Bool) async throws {
        try await appDatabase.databaseHandle.write { database in
            let lastSyncAt = Date()

            // Updating all branches at once, because there is no separate sync completion tracking for different branches
            for branch in ExpressBranch.allCases {
                let endpointType = branch.endpointType
                let updatedRecordsCount = try ExpressSyncMetadataRecord
                    .filter(ownerAddress: ownerAddress, endpointType: endpointType)
                    .updateAll(database) { record in
                        [
                            record.isInitialSyncDone.set(to: isDone),
                            record.lastSyncAt.set(to: lastSyncAt),
                        ]
                    }

                // Upsert was performed, early exit
                if updatedRecordsCount > 0 {
                    continue
                }

                try ExpressSyncMetadataRecord(
                    ownerAddress: ownerAddress,
                    endpointType: endpointType,
                    archiveCursor: nil,
                    deltaCursor: nil,
                    isInitialSyncDone: isDone,
                    lastSyncAt: lastSyncAt
                ).insert(database)
            }
        }
    }

    func clear() async throws {
        try await appDatabase.databaseHandle.write { database in
            _ = try ExpressSyncMetadataRecord
                .filter(ownerAddress: ownerAddress)
                .deleteAll(database)
        }
    }
}

// MARK: - Convenience extensions

private extension ExpressBranch {
    /// A stable value for database fetching and writing, doesn't depend on the internals of this enum.
    var endpointType: String {
        switch self {
        case .swap:
            return "swap"
        case .onramp:
            return "onramp"
        }
    }
}
