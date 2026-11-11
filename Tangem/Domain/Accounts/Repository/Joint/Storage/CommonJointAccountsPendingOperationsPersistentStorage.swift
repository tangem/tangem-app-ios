//
//  CommonJointAccountsPendingOperationsPersistentStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit
import GRDB
import TangemFoundation
import TangemAppDatabase

final class CommonJointAccountsPendingOperationsPersistentStorage {
    @Injected(\.appDatabase) private var appDatabase: AppDatabase

    private func inFlightRecords(safeAddresses: Set<String>, in database: Database) throws -> [JointOperationRecord] {
        guard safeAddresses.isNotEmpty else {
            return []
        }

        return try JointOperationRecord
            .filter(safeAddresses.contains(JointOperationRecord.Columns.safeAddress))
            .filter(JointOperationRecord.Columns.finishedAt == nil)
            .fetchAll(database)
            .filter { JointAccountOperationStatus(rawValue: $0.status)?.isInFlight == true }
            .sorted { $0.createdAt < $1.createdAt }
    }

    private func storedRecords(
        operationIds: Set<String>,
        safeAddresses: Set<String>,
        in database: Database
    ) throws -> [JointOperationRecord] {
        let touchedRecords = try JointOperationRecord.fetchAll(database, keys: Array(operationIds))
        let inFlightRecords = try inFlightRecords(safeAddresses: safeAddresses, in: database)

        return (touchedRecords + inFlightRecords).unique(by: \.id)
    }

    private func items(from records: [JointOperationRecord]) -> [JointOperationHistoryItem] {
        records.compactMap { record in
            do {
                return try TransactionHistoryRecordsMapper.mapToJointOperationHistoryItem(record)
            } catch {
                JointAccountsLogger.warning("Skipping an unreadable stored joint operation: \(error)")
                return nil
            }
        }
    }

    private func save(_ changes: JointAccountsPendingOperationsChanges, in database: Database) throws {
        if changes.removedOperationIds.isNotEmpty {
            try JointOperationsDeleteResolver(operationIds: changes.removedOperationIds).write(in: database)
        }

        try JointOperationsSaveResolver(items: changes.savedItems).write(in: database)
    }
}

// MARK: - JointAccountsPendingOperationsPersistentStorage protocol conformance

extension CommonJointAccountsPendingOperationsPersistentStorage: JointAccountsPendingOperationsPersistentStorage {
    var didUpdatePublisher: AnyPublisher<Void, Never> {
        Deferred { [appDatabase] in
            Result { try appDatabase.databaseHandle }.publisher
        }
        .flatMap { databaseHandle in
            DatabaseRegionObservation(tracking: JointOperationRecord.all())
                .publisher(in: databaseHandle)
                .map { _ in }
        }
        .catch { [weak self] error -> AnyPublisher<Void, Never> in
            JointAccountsLogger.error("Unable to observe the stored joint operations, waiting to retry", error: error)

            guard let self else {
                return Empty().eraseToAnyPublisher()
            }

            return NotificationCenter.default
                .publisher(for: UIApplication.willEnterForegroundNotification)
                .first()
                .flatMap { _ in self.didUpdatePublisher.prepend(()) }
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }

    func inFlightOperations(safeAddresses: Set<String>) throws -> [JointOperationHistoryItem] {
        let records = try appDatabase.databaseHandle.read { database in
            try inFlightRecords(safeAddresses: safeAddresses, in: database)
        }

        return items(from: records)
    }

    func operation(id: String) throws -> JointOperationHistoryItem? {
        let record = try appDatabase.databaseHandle.read { database in
            try JointOperationRecord.fetchOne(database, key: id)
        }

        return record.flatMap { items(from: [$0]).first }
    }

    func update(
        operationIds: Set<String>,
        safeAddresses: Set<String>,
        _ resolveChanges: ([JointOperationHistoryItem]) -> JointAccountsPendingOperationsChanges
    ) throws {
        try appDatabase.databaseHandle.write { database in
            let records = try storedRecords(operationIds: operationIds, safeAddresses: safeAddresses, in: database)
            let storedItems = items(from: records)
            let changes = resolveChanges(storedItems)

            guard !changes.isEmpty else {
                return
            }

            try save(changes, in: database)
        }
    }
}
