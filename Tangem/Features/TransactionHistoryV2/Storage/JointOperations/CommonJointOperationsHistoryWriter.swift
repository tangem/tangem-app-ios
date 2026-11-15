//
//  CommonJointOperationsHistoryWriter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct CommonJointOperationsHistoryWriter {
    private let writer: TransactionHistoryRecordsWriter
    private let rule = JointOperationHistoryOverwriteRule()

    init(writer: TransactionHistoryRecordsWriter) {
        self.writer = writer
    }
}

// MARK: - JointOperationsHistoryWriter protocol conformance

extension CommonJointOperationsHistoryWriter: JointOperationsHistoryWriter {
    func save(remote items: [JointOperationHistoryItem]) async throws {
        let allowedItems = items.filter { item in
            rule.shouldWrite(item.operation.status, from: .remote, over: nil)
        }

        guard allowedItems.isNotEmpty else {
            return
        }

        try await writer.save(allowedItems)
    }

    func save(local items: [JointOperationHistoryItem]) async throws {
        guard items.isNotEmpty else {
            return
        }

        try await writer.write(JointOperationsLocalSaveResolver(items: items))
    }

    func delete(operationIds: [String]) async throws {
        guard operationIds.isNotEmpty else {
            return
        }

        try await writer.write(JointOperationsDeleteResolver(operationIds: operationIds))
    }
}
