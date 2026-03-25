//
//  NewsReadStatusSortableTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//

import Testing
@testable import Tangem

@Suite(.tags(.news))
struct NewsReadStatusSortableTests {
    struct Item: NewsReadStatusSortable, Equatable {
        let id: Int
        let isRead: Bool
    }

    @Test("Sorts by read status", arguments: Self.cases())
    func sortsByReadStatus(
        caseName: String,
        items: [Item],
        expectedOrder: [Int]
    ) {
        let result = items.sortedByReadStatus()

        #expect(result.map(\.id) == expectedOrder, "Case: \(caseName)")
    }

    private static func cases() -> [(String, [Item], [Int])] {
        [
            (
                "Unread first and keeps relative order",
                [
                    .init(id: 1, isRead: true),
                    .init(id: 2, isRead: false),
                    .init(id: 3, isRead: false),
                    .init(id: 4, isRead: true),
                ],
                [2, 3, 1, 4]
            ),
            (
                "All items same read status",
                [
                    .init(id: 1, isRead: false),
                    .init(id: 2, isRead: false),
                    .init(id: 3, isRead: false),
                ],
                [1, 2, 3]
            ),
        ]
    }
}
