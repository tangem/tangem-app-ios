//
//  JointOperationsSaveResolver.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB
import TangemAppDatabase

struct JointOperationsSaveResolver {
    let items: [JointOperationHistoryItem]

    func write(in database: Database) throws {
        for item in items {
            try TransactionHistoryRecordsMapper.mapToJointOperationRecord(item).upsert(database)
            try TransactionHistoryRecordsMapper.mapToTransactionHistoryIndexRecord(item)?.insert(database, onConflict: .ignore)
        }
    }
}
