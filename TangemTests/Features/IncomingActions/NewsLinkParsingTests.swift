//
//  NewsLinkParsingTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

/// Single source of truth for news link parsing tests.
/// Keep all `news`/`newsArticle` scenarios in this suite and avoid duplicating them in `DeeplinkParserTests`.
@Suite(.tags(.news))
struct NewsLinkParsingTests {
    private let parser = DeeplinkParser()

    // MARK: - News Path Universal Link Tests

    @Test("Parses news path universal link")
    func newsPathUniversalLinkParsing() throws {
        let url = try #require(URL(string: "https://tangem.com/news/markets/190801-polygon-protiv-ethereum"))

        let action = parser.parse(url)

        guard case .navigation(let deeplink) = action else {
            Issue.record("Expected navigation action")
            return
        }

        #expect(deeplink == .newsArticle(NewsArticleDeeplink(newsId: 190801, deeplinkString: url.absoluteString)))
    }

    @Test("Parses news path universal link without slug")
    func newsPathUniversalLinkParsingWithoutSlug() throws {
        let url = try #require(URL(string: "https://tangem.com/news/markets/190801"))

        let action = parser.parse(url)

        guard case .navigation(let deeplink) = action else {
            Issue.record("Expected navigation action")
            return
        }

        #expect(deeplink == .newsArticle(NewsArticleDeeplink(newsId: 190801, deeplinkString: url.absoluteString)))
    }

    @Test("Parses news path universal link with different category")
    func newsPathUniversalLinkParsingDifferentCategory() throws {
        let url = try #require(URL(string: "https://tangem.com/news/crypto/12345-some-article"))

        let action = parser.parse(url)

        guard case .navigation(let deeplink) = action else {
            Issue.record("Expected navigation action")
            return
        }

        #expect(deeplink == .newsArticle(NewsArticleDeeplink(newsId: 12345, deeplinkString: url.absoluteString)))
    }

    @Test("Rejects news path universal link with missing components")
    func newsPathUniversalLinkParsingFailsForMissingComponents() throws {
        let url = try #require(URL(string: "https://tangem.com/news/markets"))

        let action = parser.parse(url)

        #expect(action == nil)
    }

    @Test("Rejects news path universal link with non-numeric id")
    func newsPathUniversalLinkParsingFailsForNonNumericId() throws {
        let url = try #require(URL(string: "https://tangem.com/news/markets/abc-polygon"))

        let action = parser.parse(url)

        #expect(action == nil)
    }

    @Test("Rejects non-news URLs")
    func rejectsNonNewsURLs() throws {
        let url = try #require(URL(string: "https://tangem.com/some/other/path"))

        let action = parser.parse(url)

        #expect(action == nil)
    }

    @Test("Rejects news URL with empty id")
    func rejectsNewsURLWithEmptyId() throws {
        let url = try #require(URL(string: "https://tangem.com/news/markets/-slug-only"))

        let action = parser.parse(url)

        #expect(action == nil)
    }

    // MARK: - Custom Scheme (tangem://news) Tests

    @Test("Parses tangem://news with no query as navigation to all categories")
    func customSchemeNewsAllCategories() throws {
        let url = try #require(URL(string: "tangem://news"))

        let action = parser.parse(url)

        guard case .navigation(let deeplink) = action else {
            Issue.record("Expected navigation action")
            return
        }

        #expect(deeplink == .news(NewsDeeplink(newsId: nil, categoryId: nil)))
    }

    @Test("Parses tangem://news with category_id")
    func customSchemeNewsWithCategoryId() throws {
        let url = try #require(URL(string: "tangem://news?category_id=42"))

        let action = parser.parse(url)

        guard case .navigation(let deeplink) = action else {
            Issue.record("Expected navigation action")
            return
        }

        #expect(deeplink == .news(NewsDeeplink(newsId: nil, categoryId: 42)))
    }

    @Test("Parses tangem://news with news_id")
    func customSchemeNewsWithNewsId() throws {
        let url = try #require(URL(string: "tangem://news?news_id=1001"))

        let action = parser.parse(url)

        guard case .navigation(let deeplink) = action else {
            Issue.record("Expected navigation action")
            return
        }

        #expect(deeplink == .news(NewsDeeplink(newsId: 1001, categoryId: nil)))
    }

    @Test("Parses tangem://news with both news_id and category_id (news_id takes precedence downstream)")
    func customSchemeNewsWithNewsIdAndCategoryId() throws {
        let url = try #require(URL(string: "tangem://news?news_id=1001&category_id=42"))

        let action = parser.parse(url)

        guard case .navigation(let deeplink) = action else {
            Issue.record("Expected navigation action")
            return
        }

        #expect(deeplink == .news(NewsDeeplink(newsId: 1001, categoryId: 42)))
    }

    @Test("Rejects tangem://news with non-numeric news_id")
    func customSchemeNewsRejectsNonNumericNewsId() throws {
        let url = try #require(URL(string: "tangem://news?news_id=not-a-number"))

        let action = parser.parse(url)

        #expect(action == nil)
    }

    @Test("Rejects tangem://news with non-numeric category_id")
    func customSchemeNewsRejectsNonNumericCategoryId() throws {
        let url = try #require(URL(string: "tangem://news?category_id=abc"))

        let action = parser.parse(url)

        #expect(action == nil)
    }

    @Test("Rejects tangem://news with invalid category_id characters")
    func customSchemeNewsRejectsInvalidCategoryIdCharacters() throws {
        let url = try #require(URL(string: "tangem://news?category_id=bad%20id"))

        let action = parser.parse(url)

        #expect(action == nil)
    }

    // MARK: - Integration Tests (via IncomingActionParser)

    @Test("IncomingActionParser parses news path universal link")
    func incomingActionParserParsesNewsPathUniversalLink() throws {
        let url = try #require(URL(string: "https://tangem.com/news/markets/190801-polygon-protiv-ethereum"))

        let incomingParser = IncomingActionParser()
        let action = incomingParser.parseIncomingURL(url)

        guard case .navigation(let deeplink) = action else {
            Issue.record("Expected navigation action")
            return
        }

        #expect(deeplink == .newsArticle(NewsArticleDeeplink(newsId: 190801, deeplinkString: url.absoluteString)))
    }

    @Test("IncomingActionParser parses tangem://news custom scheme")
    func incomingActionParserParsesCustomSchemeNews() throws {
        let url = try #require(URL(string: "tangem://news?category_id=7"))

        let incomingParser = IncomingActionParser()
        let action = incomingParser.parseIncomingURL(url)

        guard case .navigation(let deeplink) = action else {
            Issue.record("Expected navigation action")
            return
        }

        #expect(deeplink == .news(NewsDeeplink(newsId: nil, categoryId: 7)))
    }

    @Test("IncomingActionParser rejects tangem://news with invalid news_id and does not fall back to news list")
    func incomingActionParserRejectsInvalidNewsId() throws {
        let url = try #require(URL(string: "tangem://news?news_id=not-a-number"))

        let incomingParser = IncomingActionParser()
        let action = incomingParser.parseIncomingURL(url)

        #expect(action == nil)
    }
}
