//
//  CommonTransactionHistoryRecordsWriter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB
import TangemExpress
import TangemFoundation
import TangemAppDatabase

struct CommonTransactionHistoryRecordsWriter {
    @Injected(\.appDatabase) private var appDatabase: AppDatabase

    private func save(
        transactionRecords: [some PersistableRecord],
        indexRecords: [some PersistableRecord]
    ) async throws {
        guard transactionRecords.isNotEmpty else {
            return
        }

        try await appDatabase.databaseHandle.write { database in
            try database.saveTransactionHistory(transactionRecords: transactionRecords, indexRecords: indexRecords)
        }
    }
}

// MARK: - TransactionHistoryRecordsWriter protocol conformance

extension CommonTransactionHistoryRecordsWriter: TransactionHistoryRecordsWriter {
    func save(_ transactions: [ExchangeTransaction]) async throws {
        let transactionRecords = transactions.map { transaction in
            TransactionHistoryRecordsMapper.mapToExpressExchangeTransactionRecord(transaction)
        }
        let indexRecords = transactions.flatMap { transaction in
            TransactionHistoryRecordsMapper.mapToTransactionHistoryIndexRecords(transaction)
        }

        try await save(transactionRecords: transactionRecords, indexRecords: indexRecords)
    }

    func save(_ transactions: [OnrampTransaction]) async throws {
        let transactionRecords = transactions.map { transaction in
            TransactionHistoryRecordsMapper.mapToExpressOnrampTransactionRecord(transaction)
        }
        let indexRecords = transactions.flatMap { transaction in
            TransactionHistoryRecordsMapper.mapToTransactionHistoryIndexRecords(transaction)
        }

        try await save(transactionRecords: transactionRecords, indexRecords: indexRecords)
    }

    func save(_ items: [JointOperationHistoryItem]) async throws {
        let operationRecords = items.map(TransactionHistoryRecordsMapper.mapToJointOperationRecord)
        let indexRecords = items.compactMap(TransactionHistoryRecordsMapper.mapToTransactionHistoryIndexRecord)

        try await save(transactionRecords: operationRecords, indexRecords: indexRecords)
    }

    func write(_ resolver: some TransactionHistoryRecordsWriteResolver) async throws {
        try await appDatabase.databaseHandle.write { database in
            try resolver.write(in: database)
        }
    }
}

// MARK: - Database+

extension Database {
    func saveTransactionHistory(
        transactionRecords: [some PersistableRecord],
        indexRecords: [some PersistableRecord]
    ) throws {
        for transactionRecord in transactionRecords {
            try transactionRecord.upsert(self)
        }

        for indexRecord in indexRecords {
            // No upsert needed for index records, just do not insert if the index record already exists
            try indexRecord.insert(self, onConflict: .ignore)
        }
    }
}
