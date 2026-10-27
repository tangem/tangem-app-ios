//
//  MoralisCursorPaginatorTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import Foundation
@testable import TangemNFT

@Suite("MoralisCursorPaginatorTests")
struct MoralisCursorPaginatorTests {
    typealias Response = MoralisSolanaNetworkResult.WalletNFTsResponse

    @Test
    func followsCursorThroughShortPagesUntilItIsNil() async throws {
        let pages: [String?: String] = [
            nil: MoralisSolanaFixtures.firstPageResponse,
            "page-2": MoralisSolanaFixtures.secondPageResponse,
            "page-3": MoralisSolanaFixtures.lastPageResponse,
        ]
        let requestedCursors = RequestedCursors()

        let output: (value: [Response], errors: [NFTErrorDescriptor]) = await MoralisCursorPaginator.loadAllPages { cursor in
            requestedCursors.append(cursor)
            return try MoralisSolanaFixtures.decodeResponse(try #require(pages[cursor]))
        }

        #expect(tokenAddresses(in: output.value) == ["CorePage1Asset1", "CorePage1Asset2", "CorePage2Asset1", "CorePage3Asset1"])
        #expect(output.errors.isEmpty)
        #expect(requestedCursors.values == [nil, "page-2", "page-3"])
    }

    @Test
    func stopsWhenCursorIsAbsent() async {
        let requestedCursors = RequestedCursors()

        let output: (value: [Response], errors: [NFTErrorDescriptor]) = await MoralisCursorPaginator.loadAllPages { cursor in
            requestedCursors.append(cursor)
            return try MoralisSolanaFixtures.decodeResponse(MoralisSolanaFixtures.pageWithoutCursorResponse)
        }

        #expect(tokenAddresses(in: output.value) == ["CoreOnlyAsset"])
        #expect(output.errors.isEmpty)
        #expect(requestedCursors.values == [nil])
    }

    @Test
    func recordsErrorOnLaterPageAndRetriesItsCursor() async {
        let pages: [String?: String] = [
            nil: MoralisSolanaFixtures.firstPageResponse,
            "page-2": MoralisSolanaFixtures.secondPageResponse,
            "page-3": MoralisSolanaFixtures.lastPageResponse,
        ]
        let requestedCursors = RequestedCursors()

        let output: (value: [Response], errors: [NFTErrorDescriptor]) = await MoralisCursorPaginator.loadAllPages { cursor in
            requestedCursors.append(cursor)

            if cursor == "page-2", requestedCursors.values.filter({ $0 == "page-2" }).count == 1 {
                throw TestError.pageFailed
            }

            return try MoralisSolanaFixtures.decodeResponse(try #require(pages[cursor]))
        }

        #expect(tokenAddresses(in: output.value) == ["CorePage1Asset1", "CorePage1Asset2", "CorePage2Asset1", "CorePage3Asset1"])
        #expect(output.errors.count == 1)
        #expect(requestedCursors.values == [nil, "page-2", "page-2", "page-3"])
    }

    @Test
    func stopsWithErrorWhenFirstPageFails() async {
        let requestedCursors = RequestedCursors()

        let output: (value: [Response], errors: [NFTErrorDescriptor]) = await MoralisCursorPaginator.loadAllPages { cursor in
            requestedCursors.append(cursor)
            throw TestError.pageFailed
        }

        #expect(output.value.isEmpty)
        #expect(output.errors.count == 1)
        #expect(requestedCursors.values == [nil])
    }
}

// MARK: - Helpers

private extension MoralisCursorPaginatorTests {
    enum TestError: Error {
        case pageFailed
    }

    final class RequestedCursors {
        private(set) var values: [String?] = []

        func append(_ cursor: String?) {
            values.append(cursor)
        }
    }

    func tokenAddresses(in responses: [Response]) -> [String?] {
        responses.flatMap { $0.result ?? [] }.map(\.tokenAddress)
    }
}
