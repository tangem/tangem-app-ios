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
    typealias PageFetcher = @Sendable (_ apiProvider: ExpressAPIProvider, _ cursor: Any?) async throws -> Page

    private let apiProvider: ExpressAPIProvider
    private let cursorStorage: TransactionHistoryCursorStorage
    private let initialPageFetcher: PageFetcher
    private let deltaPageFetcher: PageFetcher

    init(
        apiProvider: ExpressAPIProvider,
        cursorStorage: TransactionHistoryCursorStorage,
        initialPageFetcher: @escaping PageFetcher,
        deltaPageFetcher: @escaping PageFetcher
    ) {
        self.apiProvider = apiProvider
        self.cursorStorage = cursorStorage
        self.initialPageFetcher = initialPageFetcher
        self.deltaPageFetcher = deltaPageFetcher
    }

    private func fetchPages(
        using pageFetcher: PageFetcher,
        handleRecordsPage: @Sendable ([Record]) async -> TransactionHistoryNextPageAction
    ) async throws {
        var cursor = await cursorStorage.cursor

        while !Task.isCancelled {
            let page = try await pageFetcher(apiProvider, cursor)

            TransactionHistoryLogger.debug(self, "Fetched page: \(page.records.count) record(s), hasMore: \(page.hasMore)")

            let action = await handleRecordsPage(page.records)

            switch action {
            case .stop:
                TransactionHistoryLogger.info(self, "Caller halted pagination; cursor left unchanged")
                return
            case .proceed:
                await cursorStorage.setCursor(page.nextCursor)
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
        await cursorStorage.clear()
        try await fetchPages(using: initialPageFetcher, handleRecordsPage: handleRecordsPage)
    }

    // [REDACTED_TODO_COMMENT]
    // starts from ~now instead of the initial walk's oldest cursor; needs the richer page model + persistent
    // sync-metadata storage ([REDACTED_INFO])
    func syncDelta(handleRecordsPage: @Sendable ([Record]) async -> TransactionHistoryNextPageAction) async throws {
        try await fetchPages(using: deltaPageFetcher, handleRecordsPage: handleRecordsPage)
    }
}

// MARK: - CustomStringConvertible protocol conformance

extension CommonTransactionHistoryNetworkService: CustomStringConvertible {
    var description: String {
        objectDescription(self)
    }
}

// MARK: - Auxiliary types

extension CommonTransactionHistoryNetworkService {
    struct Page: @unchecked Sendable {
        let records: [Record]
        /// Opaque cursor (hence `Any`) for the next page.
        let nextCursor: Any?
        let hasMore: Bool
    }
}
