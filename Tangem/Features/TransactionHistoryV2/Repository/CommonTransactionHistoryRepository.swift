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
    private let exchangeStorage: any TransactionHistoryRecordsStorage<ExchangeTransaction>
    private let onrampStorage: any TransactionHistoryRecordsStorage<OnrampTransaction>
    private let exchangeNetworkService: any TransactionHistoryNetworkService<ExchangeTransaction>
    private let onrampNetworkService: any TransactionHistoryNetworkService<OnrampTransaction>

    init(
        exchangeStorage: any TransactionHistoryRecordsStorage<ExchangeTransaction>,
        onrampStorage: any TransactionHistoryRecordsStorage<OnrampTransaction>,
        exchangeNetworkService: any TransactionHistoryNetworkService<ExchangeTransaction>,
        onrampNetworkService: any TransactionHistoryNetworkService<OnrampTransaction>
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
    var exchangeHistoryUpdates: AsyncStream<[ExchangeTransaction]> {
        exchangeStorage.recordsUpdates
    }

    var onrampHistoryUpdates: AsyncStream<[OnrampTransaction]> {
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
