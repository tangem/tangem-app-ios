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

        #expect(deeplink.destination == .news)
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

        #expect(deeplink.destination == .news)
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

        #expect(deeplink.destination == .news)
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

        #expect(deeplink.destination == .news)
        #expect(deeplink.params.id == "190801")
    }
}
