//
//  CommonHistoryNetworkService.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class CommonHistoryNetworkService<Record: HistoryRecord>: @unchecked Sendable {
    typealias PageFetcher = @Sendable (_ cursor: Any?) async throws -> Page

    private let cursorStorage: any HistoryCursorStorage
    private let recordsStorage: any HistoryRecordsStorage<Record>
    private let pageFetcher: PageFetcher

    init(
        cursorStorage: any HistoryCursorStorage,
        recordsStorage: any HistoryRecordsStorage<Record>,
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

// MARK: - HistoryNetworkService protocol conformance

extension CommonHistoryNetworkService: HistoryNetworkService {
    func syncInitial() async throws {
        await cursorStorage.clear()
        try await fetchPages()
    }

    func syncDelta() async throws {
        try await fetchPages()
    }
}

// MARK: - Auxiliary types

extension CommonHistoryNetworkService {
    struct Page: @unchecked Sendable {
        let records: [Record]
        /// Opaque cursor for the next page.
        let nextCursor: Any
        let hasMore: Bool
    }
}
