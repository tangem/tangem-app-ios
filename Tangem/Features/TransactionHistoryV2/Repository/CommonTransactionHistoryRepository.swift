//
//  CommonTransactionHistoryRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

final class CommonTransactionHistoryRepository: Sendable {
    private let exchangeStorage: any TransactionHistoryRecordsStorage<ExchangeHistoryRecord>
    private let onrampStorage: any TransactionHistoryRecordsStorage<OnrampHistoryRecord>
    private let exchangeNetworkService: any TransactionHistoryNetworkService
    private let onrampNetworkService: any TransactionHistoryNetworkService

    init(
        exchangeStorage: any TransactionHistoryRecordsStorage<ExchangeHistoryRecord>,
        onrampStorage: any TransactionHistoryRecordsStorage<OnrampHistoryRecord>,
        exchangeNetworkService: any TransactionHistoryNetworkService,
        onrampNetworkService: any TransactionHistoryNetworkService
    ) {
        self.exchangeStorage = exchangeStorage
        self.onrampStorage = onrampStorage
        self.exchangeNetworkService = exchangeNetworkService
        self.onrampNetworkService = onrampNetworkService
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
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { [exchangeNetworkService] in
                try await exchangeNetworkService.syncInitial()
            }
            group.addTask { [onrampNetworkService] in
                try await onrampNetworkService.syncInitial()
            }
            try await group.waitForAll()
        }
    }

    func syncDelta() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { [exchangeNetworkService] in
                try await exchangeNetworkService.syncDelta()
            }
            group.addTask { [onrampNetworkService] in
                try await onrampNetworkService.syncDelta()
            }
            try await group.waitForAll()
        }
    }
}
