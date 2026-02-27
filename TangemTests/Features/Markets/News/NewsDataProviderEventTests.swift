//
//  NewsDataProviderEventTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import Testing
@testable import Tangem

@Suite(.tags(.news))
struct NewsDataProviderEventTests {
    @Test("Event equality behavior", arguments: Self.equalityCases())
    func eventEqualityBehavior(
        caseName: String,
        lhs: NewsDataProvider.Event,
        rhs: NewsDataProvider.Event,
        expected: Bool
    ) {
        #expect((lhs == rhs) == expected, "Case: \(caseName)")
    }

    private static func equalityCases() -> [(String, NewsDataProvider.Event, NewsDataProvider.Event, Bool)] {
        let items = Self.sampleItems()
        return [
            (
                "failedToFetchData ignores error payload",
                .failedToFetchData(error: NSError(domain: "first", code: 1)),
                .failedToFetchData(error: NSError(domain: "second", code: 2)),
                true
            ),
            (
                "appendedItems compares ids and lastPage",
                .appendedItems(items: [items.item1, items.item2], lastPage: false),
                .appendedItems(items: [items.item1, items.item2], lastPage: false),
                true
            ),
            (
                "appendedItems different order",
                .appendedItems(items: [items.item1, items.item2], lastPage: false),
                .appendedItems(items: [items.item2, items.item1], lastPage: false),
                false
            ),
            (
                "appendedItems different lastPage",
                .appendedItems(items: [items.item1, items.item2], lastPage: false),
                .appendedItems(items: [items.item1, items.item2], lastPage: true),
                false
            ),
        ]
    }

    private static func sampleItems() -> (item1: NewsDTO.List.Item, item2: NewsDTO.List.Item) {
        let now = Date()
        let item1 = NewsDTO.List.Item(
            id: 1,
            createdAt: now,
            score: 1.0,
            language: "en",
            isTrending: false,
            categories: [],
            relatedTokens: [],
            title: "First",
            newsUrl: "https://example.com/1"
        )
        let item2 = NewsDTO.List.Item(
            id: 2,
            createdAt: now,
            score: 1.0,
            language: "en",
            isTrending: false,
            categories: [],
            relatedTokens: [],
            title: "Second",
            newsUrl: "https://example.com/2"
        )
        return (item1, item2)
    }
}
