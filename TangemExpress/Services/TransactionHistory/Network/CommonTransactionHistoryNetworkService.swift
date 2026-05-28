//
//  CommonTransactionHistoryNetworkService.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class CommonTransactionHistoryNetworkService<Record: TransactionHistoryRecord>: @unchecked Sendable {
    typealias PageFetcher = @Sendable (_ cursor: Any?) async throws -> Page

    private let cursorStorage: any TransactionHistoryCursorStorage
    private let pageFetcher: PageFetcher

    init(
        cursorStorage: any TransactionHistoryCursorStorage,
        pageFetcher: @escaping PageFetcher
    ) {
        self.cursorStorage = cursorStorage
        self.pageFetcher = pageFetcher
    }

    private func fetchPages(handleRecordsPage: @Sendable ([Record]) async -> TransactionHistoryNextPageAction) async throws {
        var cursor = await cursorStorage.cursor

        while !Task.isCancelled {
            let page = try await pageFetcher(cursor)

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
        try await fetchPages(handleRecordsPage: handleRecordsPage)
    }

    func syncDelta(handleRecordsPage: @Sendable ([Record]) async -> TransactionHistoryNextPageAction) async throws {
        try await fetchPages(handleRecordsPage: handleRecordsPage)
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
        /// Opaque cursor for the next page.
        let nextCursor: Any
        let hasMore: Bool
    }
}
