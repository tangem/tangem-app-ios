//
//  NewsIncomingLinkParserTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

/// Single source of truth for news link parsing tests.
/// Keep all `news`/`newsArticle` parser scenarios in this suite and avoid duplicating them in `DefaultIncomingLinkParserTests`.
@Suite(.tags(.news))
struct NewsIncomingLinkParserTests {
    private let parser = NewsIncomingLinkParser()

    // MARK: - News Path Universal Link Tests

    @Test("Parses news path universal link")
    func newsPathUniversalLinkParsing() throws {
        let url = try #require(URL(string: "https://tangem.com/news/markets/190801-polygon-protiv-ethereum"))

        let action = try parser.parse(url)

        guard case .navigation(let deeplink) = action else {
            Issue.record("Expected navigation action")
            return
        }

        #expect(deeplink.destination == .newsArticle)
        #expect(deeplink.params.id == "190801")
        #expect(deeplink.deeplinkString == url.absoluteString)
    }

    @Test("Parses news path universal link without slug")
    func newsPathUniversalLinkParsingWithoutSlug() throws {
        let url = try #require(URL(string: "https://tangem.com/news/markets/190801"))

        let action = try parser.parse(url)

        guard case .navigation(let deeplink) = action else {
            Issue.record("Expected navigation action")
            return
        }

        #expect(deeplink.destination == .newsArticle)
        #expect(deeplink.params.id == "190801")
    }

    @Test("Parses news path universal link with different category")
    func newsPathUniversalLinkParsingDifferentCategory() throws {
        let url = try #require(URL(string: "https://tangem.com/news/crypto/12345-some-article"))

        let action = try parser.parse(url)

        guard case .navigation(let deeplink) = action else {
            Issue.record("Expected navigation action")
            return
        }

        #expect(deeplink.destination == .newsArticle)
        #expect(deeplink.params.id == "12345")
    }

    @Test("Rejects news path universal link with missing components")
    func newsPathUniversalLinkParsingFailsForMissingComponents() throws {
        let url = try #require(URL(string: "https://tangem.com/news/markets"))

        let action = try parser.parse(url)

        #expect(action == nil)
    }

    @Test("Rejects news path universal link with non-numeric id")
    func newsPathUniversalLinkParsingFailsForNonNumericId() throws {
        let url = try #require(URL(string: "https://tangem.com/news/markets/abc-polygon"))

        let action = try parser.parse(url)

        #expect(action == nil)
    }

    @Test("Rejects non-news URLs")
    func rejectsNonNewsURLs() throws {
        let url = try #require(URL(string: "https://tangem.com/some/other/path"))

        let action = try parser.parse(url)

        #expect(action == nil)
    }

    @Test("Rejects news URL with empty id")
    func rejectsNewsURLWithEmptyId() throws {
        let url = try #require(URL(string: "https://tangem.com/news/markets/-slug-only"))

        let action = try parser.parse(url)

        #expect(action == nil)
    }

    // MARK: - Custom Scheme (tangem://news) Tests

    @Test("Parses tangem://news with no query as navigation to all categories")
    func customSchemeNewsAllCategories() throws {
        let url = try #require(URL(string: "tangem://news"))

        let action = try parser.parse(url)

        guard case .navigation(let deeplink) = action else {
            Issue.record("Expected navigation action")
            return
        }

        #expect(deeplink.destination == .news)
        #expect(deeplink.params.id == nil)
        #expect(deeplink.params.categoryId == nil)
        #expect(deeplink.deeplinkString == url.absoluteString)
    }

    @Test("Parses tangem://news with category_id")
    func customSchemeNewsWithCategoryId() throws {
        let url = try #require(URL(string: "tangem://news?category_id=42"))

        let action = try parser.parse(url)

        guard case .navigation(let deeplink) = action else {
            Issue.record("Expected navigation action")
            return
        }

        #expect(deeplink.destination == .news)
        #expect(deeplink.params.categoryId == "42")
        #expect(deeplink.params.id == nil)
    }

    @Test("Parses tangem://news with id")
    func customSchemeNewsWithId() throws {
        let url = try #require(URL(string: "tangem://news?id=1001"))

        let action = try parser.parse(url)

        guard case .navigation(let deeplink) = action else {
            Issue.record("Expected navigation action")
            return
        }

        #expect(deeplink.destination == .news)
        #expect(deeplink.params.id == "1001")
        #expect(deeplink.params.categoryId == nil)
    }

    @Test("Parses tangem://news with both id and category_id (id takes precedence downstream)")
    func customSchemeNewsWithIdAndCategoryId() throws {
        let url = try #require(URL(string: "tangem://news?id=1001&category_id=42"))

        let action = try parser.parse(url)

        guard case .navigation(let deeplink) = action else {
            Issue.record("Expected navigation action")
            return
        }

        #expect(deeplink.destination == .news)
        #expect(deeplink.params.id == "1001")
        #expect(deeplink.params.categoryId == "42")
    }

    @Test("Rejects tangem://news with non-numeric id")
    func customSchemeNewsRejectsNonNumericId() throws {
        let url = try #require(URL(string: "tangem://news?id=not-a-number"))

        let action = try parser.parse(url)

        #expect(action == nil)
    }

    @Test("Rejects tangem://news with non-numeric category_id")
    func customSchemeNewsRejectsNonNumericCategoryId() throws {
        let url = try #require(URL(string: "tangem://news?category_id=abc"))

        let action = try parser.parse(url)

        #expect(action == nil)
    }

    @Test("Rejects tangem://news with invalid category_id characters")
    func customSchemeNewsRejectsInvalidCategoryIdCharacters() throws {
        let url = try #require(URL(string: "tangem://news?category_id=bad%20id"))

        let action = try parser.parse(url)

        #expect(action == nil)
    }

    @Test("Rejects non-news tangem:// scheme URLs")
    func customSchemeRejectsNonNewsHost() throws {
        let url = try #require(URL(string: "tangem://token?token_id=btc&network_id=bitcoin"))

        let action = try parser.parse(url)

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

        #expect(deeplink.destination == .newsArticle)
        #expect(deeplink.params.id == "190801")
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

        #expect(deeplink.destination == .news)
        #expect(deeplink.params.categoryId == "7")
    }
}
