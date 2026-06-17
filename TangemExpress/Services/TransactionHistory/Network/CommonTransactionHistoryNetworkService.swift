//
//  CommonTransactionHistoryNetworkService.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// - Note: No mutable state, so this type is considered to be `Sendable` by definition.
final class CommonTransactionHistoryNetworkService<Record: TransactionHistoryRecord>: @unchecked Sendable {
    /// - Parameter cursor: Opaque cursor for the next page.
    typealias PageFetcher = @Sendable (_ apiProvider: ExpressAPIProvider, _ cursor: Any?) async throws -> TransactionHistoryPage<Record>

    private let apiProvider: ExpressAPIProvider
    private let initialCursorStorage: TransactionHistoryCursorStorage
    private let deltaCursorStorage: TransactionHistoryCursorStorage
    private let initialPageFetcher: PageFetcher
    private let deltaPageFetcher: PageFetcher

    init(
        apiProvider: ExpressAPIProvider,
        initialCursorStorage: TransactionHistoryCursorStorage,
        deltaCursorStorage: TransactionHistoryCursorStorage,
        initialPageFetcher: @escaping PageFetcher,
        deltaPageFetcher: @escaping PageFetcher
    ) {
        self.apiProvider = apiProvider
        self.initialCursorStorage = initialCursorStorage
        self.deltaCursorStorage = deltaCursorStorage
        self.initialPageFetcher = initialPageFetcher
        self.deltaPageFetcher = deltaPageFetcher
    }

    private func fetchPages(
        using pageFetcher: PageFetcher,
        primaryCursorStorage: TransactionHistoryCursorStorage,
        auxiliaryCursorStorage: TransactionHistoryCursorStorage?,
        handleRecordsPage: @Sendable ([Record]) async -> TransactionHistoryNextPageAction
    ) async throws {
        var cursor = await primaryCursorStorage.cursor // Updated inside the loop after each page is processed, therefore `var`

        while !Task.isCancelled {
            let page = try await pageFetcher(apiProvider, cursor)

            TransactionHistoryLogger.debug(self, "Fetched page: \(page.records.count) record(s), hasMore: \(page.hasMore)")

            let action = await handleRecordsPage(page.records)

            switch action {
            case .stop:
                TransactionHistoryLogger.info(self, "Caller halted pagination; cursor left unchanged")
                return
            case .proceed:
                await primaryCursorStorage.setCursor(page.nextCursor)
                // Only the first page of the initial sync API has a valid cursor for the delta sync
                // See [REDACTED_INFO]
                // for details
                let isFirstPage = cursor == nil // The first page is always requested w/o a cursor
                if isFirstPage, let auxiliaryCursorStorage {
                    await auxiliaryCursorStorage.setCursor(page.startDeltaCursor)
                }
            }

            guard page.hasMore else {
                break
            }

            cursor = page.nextCursor
        }
    }
}

// MARK: - TransactionHistoryNetworkService protocol conformance

extension CommonTransactionHistoryNetworkService: TransactionHistoryNetworkService {
    func syncInitial(handleRecordsPage: @Sendable ([Record]) async -> TransactionHistoryNextPageAction) async throws {
        try await fetchPages(
            using: initialPageFetcher,
            primaryCursorStorage: initialCursorStorage,
            auxiliaryCursorStorage: deltaCursorStorage,
            handleRecordsPage: handleRecordsPage
        )
    }

    func syncDelta(handleRecordsPage: @Sendable ([Record]) async -> TransactionHistoryNextPageAction) async throws {
        try await fetchPages(
            using: deltaPageFetcher,
            primaryCursorStorage: deltaCursorStorage,
            // Delta sync doesn't have an aux cursor (i.e. a cursor for another delta sync) to save,
            // therefore no storage is needed
            auxiliaryCursorStorage: nil,
            handleRecordsPage: handleRecordsPage
        )
    }
}

// MARK: - CustomStringConvertible protocol conformance

extension CommonTransactionHistoryNetworkService: CustomStringConvertible {
    var description: String {
        objectDescription(self)
    }
}
