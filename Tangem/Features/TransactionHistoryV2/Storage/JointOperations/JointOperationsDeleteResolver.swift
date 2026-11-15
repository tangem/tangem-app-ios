//
//  JointOperationsDeleteResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB
import TangemAppDatabase

struct JointOperationsDeleteResolver {
    let operationIds: [String]
}

// MARK: - TransactionHistoryRecordsWriteResolver protocol conformance

extension JointOperationsDeleteResolver: TransactionHistoryRecordsWriteResolver {
    func write(in database: Database) throws {
        try TransactionHistoryIndexRecord
            .filter(TransactionHistoryIndexRecord.Columns.entityType == TransactionHistoryIndexRecord.Values.EntityType.jointOperation)
            .filter(operationIds.contains(TransactionHistoryIndexRecord.Columns.entityID))
            .deleteAll(database)

        try JointOperationRecord.deleteAll(database, keys: operationIds)
    }
}
