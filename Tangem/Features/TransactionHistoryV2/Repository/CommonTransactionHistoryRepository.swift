//
//  CommonTransactionHistoryRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemFoundation

final class CommonTransactionHistoryRepository: Sendable {
    private let exchangeStorage: any TransactionHistoryRecordsStorage<ExchangeHistoryRecord>
    private let onrampStorage: any TransactionHistoryRecordsStorage<OnrampHistoryRecord>
    private let exchangeNetworkService: any TransactionHistoryNetworkService<ExchangeHistoryRecord>
    private let onrampNetworkService: any TransactionHistoryNetworkService<OnrampHistoryRecord>

    init(
        exchangeStorage: any TransactionHistoryRecordsStorage<ExchangeHistoryRecord>,
        onrampStorage: any TransactionHistoryRecordsStorage<OnrampHistoryRecord>,
        exchangeNetworkService: any TransactionHistoryNetworkService<ExchangeHistoryRecord>,
        onrampNetworkService: any TransactionHistoryNetworkService<OnrampHistoryRecord>
    ) {
        self.exchangeStorage = exchangeStorage
        self.onrampStorage = onrampStorage
        self.exchangeNetworkService = exchangeNetworkService
        self.onrampNetworkService = onrampNetworkService
    }

    private func persist<Record>(
        _ records: [Record],
        ofKind kind: @autoclosure () -> String,
        into storage: some TransactionHistoryRecordsStorage<Record>
    ) async -> TransactionHistoryNextPageAction {
        do {
            try await storage.updateOrAppend(records)
            return .proceed
        } catch {
            TransactionHistoryLogger.error(self, "Failed to persist \(kind()) history records; halting pagination", error: error)
            return .stop
        }
    }
}

// MARK: - TransactionHistoryRepository protocol conformance

extension CommonTransactionHistoryRepository: TransactionHistoryRepository {
    var exchangeHistoryUpdates: AsyncStream<[ExchangeHistoryRecord]> {
        exchangeStorage.recordsUpdates
    }

    var onrampHistoryUpdates: AsyncStream<[OnrampHistoryRecord]> {
        onrampStorage.recordsUpdates
    }

    func syncInitial() async throws {
        try await withThrowingTaskGroup { group in
            group.addTask { [exchangeNetworkService, exchangeStorage, self] in
                try await exchangeNetworkService.syncInitial { records in
                    await self.persist(records, ofKind: "exchange", into: exchangeStorage)
                }
            }
            group.addTask { [onrampNetworkService, onrampStorage, self] in
                try await onrampNetworkService.syncInitial { records in
                    await self.persist(records, ofKind: "onramp", into: onrampStorage)
                }
            }
            try await group.waitForAll()
        }
    }

    func syncDelta() async throws {
        try await withThrowingTaskGroup { group in
            group.addTask { [exchangeNetworkService, exchangeStorage, self] in
                try await exchangeNetworkService.syncDelta { records in
                    await self.persist(records, ofKind: "exchange", into: exchangeStorage)
                }
            }
            group.addTask { [onrampNetworkService, onrampStorage, self] in
                try await onrampNetworkService.syncDelta { records in
                    await self.persist(records, ofKind: "onramp", into: onrampStorage)
                }
            }
            try await group.waitForAll()
        }
    }
}

// MARK: - CustomStringConvertible protocol conformance

extension CommonTransactionHistoryRepository: CustomStringConvertible {
    var description: String {
        objectDescription(self)
    }
}
