//
//  CommonTransactionHistoryRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress
import TangemFoundation

final class CommonTransactionHistoryRepository: Sendable {
    private let reader: TransactionHistoryRecordsReader
    private let writer: TransactionHistoryRecordsWriter
    private let exchangeNetworkService: any TransactionHistoryNetworkService<ExchangeTransaction>
    private let onrampNetworkService: any TransactionHistoryNetworkService<OnrampTransaction>

    init(
        reader: TransactionHistoryRecordsReader,
        writer: TransactionHistoryRecordsWriter,
        exchangeNetworkService: any TransactionHistoryNetworkService<ExchangeTransaction>,
        onrampNetworkService: any TransactionHistoryNetworkService<OnrampTransaction>
    ) {
        self.reader = reader
        self.writer = writer
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
    func historyUpdates(
        for walletModelId: WalletModelId,
        walletModelAddressesPublisher: some Publisher<[String], Never>
    ) -> AsyncStream<[TransactionHistoryRecordsReader.Record]> {
        reader.updates(for: walletModelId, walletModelAddressesPublisher: walletModelAddressesPublisher)
    }

    func fetchNextPage() async throws {
        try await reader.fetchNextPage()
    }

    func syncInitial() async throws {
        try await withThrowingTaskGroup { group in
            group.addTask { [exchangeNetworkService, writer, self] in
                try await exchangeNetworkService.syncInitial { records in
                    await self.persist(records, branch: .swap) { try await writer.save($0) }
                }
            }
            group.addTask { [onrampNetworkService, writer, self] in
                try await onrampNetworkService.syncInitial { records in
                    await self.persist(records, branch: .onramp) { try await writer.save($0) }
                }
            }
            try await group.waitForAll()
        }
    }

    func syncDelta() async throws {
        try await withThrowingTaskGroup { group in
            group.addTask { [exchangeNetworkService, writer, self] in
                try await exchangeNetworkService.syncDelta { records in
                    await self.persist(records, branch: .swap) { try await writer.save($0) }
                }
            }
            group.addTask { [onrampNetworkService, writer, self] in
                try await onrampNetworkService.syncDelta { records in
                    await self.persist(records, branch: .onramp) { try await writer.save($0) }
                }
            }
            try await group.waitForAll()
        }
    }

    func add(_ transaction: ExchangeTransaction) async throws {
        try await writer.save([transaction])
    }

    func add(_ transaction: OnrampTransaction) async throws {
        try await writer.save([transaction])
    }
}

// MARK: - CustomStringConvertible protocol conformance

extension CommonTransactionHistoryRepository: CustomStringConvertible {
    var description: String {
        objectDescription(self)
    }
}
