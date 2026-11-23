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

    init(writer: TransactionHistoryRecordsWriter) {
        self.writer = writer
    }
}

// MARK: - JointOperationsHistoryWriter protocol conformance

extension CommonJointOperationsHistoryWriter: JointOperationsHistoryWriter {
    func save(remote items: [JointOperationHistoryItem]) async throws {
        guard items.isNotEmpty else {
            return
        }

        try await writer.save(items)
    }
}
