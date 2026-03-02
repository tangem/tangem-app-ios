//
//  NewsItemViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import Testing
@testable import Tangem

@Suite(.tags(.news))
struct NewsItemViewModelTests {
    @Test("withIsRead preserves fields and updates read status")
    func withIsReadPreservesFieldsAndUpdatesReadStatus() throws {
        let token = NewsItemViewModel.RelatedToken(
            id: "btc",
            symbol: "BTC",
            iconURL: try #require(URL(string: "https://example.com/btc.png"))
        )

        let item = NewsItemViewModel(
            id: 1,
            score: "9.9",
            category: "Markets",
            relatedTokens: [token],
            title: "Title",
            relativeTime: "1h ago",
            isTrending: true,
            newsUrl: "https://example.com/news",
            isRead: false
        )

        let updated = item.withIsRead(true)

        #expect(updated.id == item.id)
        #expect(updated.score == item.score)
        #expect(updated.category == item.category)
        #expect(updated.relatedTokens.count == item.relatedTokens.count)
        #expect(updated.title == item.title)
        #expect(updated.relativeTime == item.relativeTime)
        #expect(updated.isTrending == item.isTrending)
        #expect(updated.newsUrl == item.newsUrl)
        #expect(updated.isRead == true)
    }
}
