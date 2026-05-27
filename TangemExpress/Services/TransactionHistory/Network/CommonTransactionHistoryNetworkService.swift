//
//  CommonTransactionHistoryNetworkService.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class CommonTransactionHistoryNetworkService<Record: TransactionHistoryRecord>: @unchecked Sendable {
    typealias PageFetcher = @Sendable (_ cursor: Any?) async throws -> Page

    private let cursorStorage: any TransactionHistoryCursorStorage
    private let recordsStorage: any TransactionHistoryRecordsStorage<Record>
    private let pageFetcher: PageFetcher

    init(
        cursorStorage: any TransactionHistoryCursorStorage,
        recordsStorage: any TransactionHistoryRecordsStorage<Record>,
        pageFetcher: @escaping PageFetcher
    ) {
        self.cursorStorage = cursorStorage
        self.recordsStorage = recordsStorage
        self.pageFetcher = pageFetcher
    }

    private func fetchPages() async throws {
        var cursor: Any? = await cursorStorage.cursor

        while !Task.isCancelled {
            let page = try await pageFetcher(cursor)

            await recordsStorage.updateOrAppend(page.records)
            await cursorStorage.setCursor(page.nextCursor)

            guard page.hasMore else { break }
            cursor = page.nextCursor
        }
    }
}

// MARK: - TransactionHistoryNetworkService protocol conformance

extension CommonTransactionHistoryNetworkService: TransactionHistoryNetworkService {
    func syncInitial() async throws {
        await cursorStorage.clear()
        try await fetchPages()
    }

    func syncDelta() async throws {
        try await fetchPages()
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
