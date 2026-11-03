//
//  CommonJointOperationsSyncMetadataStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemAppDatabase

struct CommonJointOperationsSyncMetadataStorage {
    @Injected(\.appDatabase) private var appDatabase: AppDatabase

    private let hashedUserWalletID: String

    init(userWalletId: UserWalletId) {
        hashedUserWalletID = JointOperationsSyncMetadataUserWalletIDHasher.hash(userWalletId)
    }

    private func fetchRecord() async throws -> JointOperationsSyncMetadataRecord? {
        return try await appDatabase.databaseHandle.read { database in
            try JointOperationsSyncMetadataRecord
                .filter(walletID: hashedUserWalletID)
                .fetchOne(database)
        }
    }
}

// MARK: - JointOperationsSyncMetadataStorage protocol conformance

extension CommonJointOperationsSyncMetadataStorage: JointOperationsSyncMetadataStorage {
    func archiveCursor() async throws -> String? {
        return try await fetchRecord()?.archiveCursor
    }

    func setArchiveCursor(_ cursor: String?) async throws {
        try await appDatabase.databaseHandle.write { database in
            let lastSyncAt = Date()

            let updatedRecordsCount = try JointOperationsSyncMetadataRecord
                .filter(walletID: hashedUserWalletID)
                .updateAll(database) { record in
                    [
                        record.archiveCursor.set(to: cursor),
                        record.lastSyncAt.set(to: lastSyncAt),
                    ]
                }

            if updatedRecordsCount > 0 {
                return
            }

            try JointOperationsSyncMetadataRecord(
                walletID: hashedUserWalletID,
                archiveCursor: cursor,
                deltaCursor: nil,
                isInitialSyncDone: false,
                lastSyncAt: lastSyncAt
            ).insert(database)
        }
    }

    func deltaCursor() async throws -> String? {
        return try await fetchRecord()?.deltaCursor
    }

    func setDeltaCursor(_ cursor: String?) async throws {
        try await appDatabase.databaseHandle.write { database in
            let lastSyncAt = Date()

            let updatedRecordsCount = try JointOperationsSyncMetadataRecord
                .filter(walletID: hashedUserWalletID)
                .updateAll(database) { record in
                    [
                        record.deltaCursor.set(to: cursor),
                        record.lastSyncAt.set(to: lastSyncAt),
                    ]
                }

            if updatedRecordsCount > 0 {
                return
            }

            try JointOperationsSyncMetadataRecord(
                walletID: hashedUserWalletID,
                archiveCursor: nil,
                deltaCursor: cursor,
                isInitialSyncDone: false,
                lastSyncAt: lastSyncAt
            ).insert(database)
        }
    }

    func isInitialSyncDone() async throws -> Bool {
        return try await fetchRecord()?.isInitialSyncDone ?? false
    }

    func setIsInitialSyncDone(_ isDone: Bool) async throws {
        try await appDatabase.databaseHandle.write { database in
            let lastSyncAt = Date()

            let updatedRecordsCount = try JointOperationsSyncMetadataRecord
                .filter(walletID: hashedUserWalletID)
                .updateAll(database) { record in
                    [
                        record.isInitialSyncDone.set(to: isDone),
                        record.lastSyncAt.set(to: lastSyncAt),
                    ]
                }

            if updatedRecordsCount > 0 {
                return
            }

            try JointOperationsSyncMetadataRecord(
                walletID: hashedUserWalletID,
                archiveCursor: nil,
                deltaCursor: nil,
                isInitialSyncDone: isDone,
                lastSyncAt: lastSyncAt
            ).insert(database)
        }
    }

    func clear() async throws {
        try await appDatabase.databaseHandle.write { database in
            _ = try JointOperationsSyncMetadataRecord
                .filter(walletID: hashedUserWalletID)
                .deleteAll(database)
        }
    }
}
