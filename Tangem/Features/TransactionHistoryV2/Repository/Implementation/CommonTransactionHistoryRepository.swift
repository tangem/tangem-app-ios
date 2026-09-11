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
    private let storage: any TransactionHistoryRecordsStorage
    private let exchangeNetworkService: any TransactionHistoryNetworkService<ExchangeTransaction>
    private let onrampNetworkService: any TransactionHistoryNetworkService<OnrampTransaction>

    init(
        storage: any TransactionHistoryRecordsStorage,
        exchangeNetworkService: any TransactionHistoryNetworkService<ExchangeTransaction>,
        onrampNetworkService: any TransactionHistoryNetworkService<OnrampTransaction>
    ) {
        self.storage = storage
        self.exchangeNetworkService = exchangeNetworkService
        self.onrampNetworkService = onrampNetworkService
    }

    private func persist<Record>(
        _ records: [Record],
        branch: ExpressBranch,
        using save: ([Record]) async throws -> Void
    ) async -> TransactionHistoryNextPageAction {
        do {
            try await save(records)
            return .proceed
        } catch {
            TransactionHistoryLogger.error(self, "Failed to persist \(branch.rawValue) history records; halting pagination", error: error)
            return .stop
        }
    }
}

// MARK: - TransactionHistoryRepository protocol conformance

extension CommonTransactionHistoryRepository: TransactionHistoryRepository {
    func historyUpdates(for currency: ExpressCurrency) -> AsyncStream<[TransactionHistoryExpressExtraInfo]> {
        storage.updates(for: currency)
    }

    func syncInitial() async throws {
        try await withThrowingTaskGroup { group in
            group.addTask { [exchangeNetworkService, storage, self] in
                try await exchangeNetworkService.syncInitial { records in
                    await self.persist(records, branch: .swap) { try await storage.save($0) }
                }
            }
            group.addTask { [onrampNetworkService, storage, self] in
                try await onrampNetworkService.syncInitial { records in
                    await self.persist(records, branch: .onramp) { try await storage.save($0) }
                }
            }
            try await group.waitForAll()
        }
    }

    func syncDelta() async throws {
        try await withThrowingTaskGroup { group in
            group.addTask { [exchangeNetworkService, storage, self] in
                try await exchangeNetworkService.syncDelta { records in
                    await self.persist(records, branch: .swap) { try await storage.save($0) }
                }
            }
            group.addTask { [onrampNetworkService, storage, self] in
                try await onrampNetworkService.syncDelta { records in
                    await self.persist(records, branch: .onramp) { try await storage.save($0) }
                }
            }
            try await group.waitForAll()
        }
    }

    func fetchNextPage() async throws {
        try await storage.fetchNextPage()
    }

    func add(_ transaction: ExchangeTransaction) async throws {
        try await storage.save([transaction])
    }

    func add(_ transaction: OnrampTransaction) async throws {
        try await storage.save([transaction])
    }
}

// MARK: - CustomStringConvertible protocol conformance

extension CommonTransactionHistoryRepository: CustomStringConvertible {
    var description: String {
        objectDescription(self)
    }
}
