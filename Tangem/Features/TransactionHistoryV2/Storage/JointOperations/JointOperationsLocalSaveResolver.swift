//
//  JointOperationsLocalSaveResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB
import TangemAppDatabase

struct JointOperationsLocalSaveResolver {
    let items: [JointOperationHistoryItem]

    private let rule = JointOperationHistoryOverwriteRule()

    init(items: [JointOperationHistoryItem]) {
        self.items = items
    }

    private func storedStatuses(in database: Database) throws -> [String: JointAccountOperationStatus] {
        try JointOperationRecord
            .fetchAll(database, keys: items.map(\.operation.id))
            .reduce(into: [:]) { statuses, record in
                statuses[record.id] = JointAccountOperationStatus(rawValue: record.status) ?? .unknown
            }
    }
}

// MARK: - TransactionHistoryRecordsWriteResolver protocol conformance

extension JointOperationsLocalSaveResolver: TransactionHistoryRecordsWriteResolver {
    func write(in database: Database) throws {
        let storedStatuses = try storedStatuses(in: database)
        let allowedItems = items.filter { item in
            rule.shouldWrite(item.operation.status, from: .local, over: storedStatuses[item.operation.id])
        }

        try database.saveTransactionHistory(
            transactionRecords: allowedItems.map(TransactionHistoryRecordsMapper.mapToJointOperationRecord),
            indexRecords: allowedItems.compactMap(TransactionHistoryRecordsMapper.mapToTransactionHistoryIndexRecord)
        )
    }
}
