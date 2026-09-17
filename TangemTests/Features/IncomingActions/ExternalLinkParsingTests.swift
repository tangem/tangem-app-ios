//
//  ExternalLinkParsingTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

/// The last word on a link of ours: a page nobody claimed is a page to open. Asserted through the whole
/// chain, because that is where the rule lives — the terminal parser runs after every other one.
@Suite("External link parsing")
struct ExternalLinkParsingTests {
    private let parser = IncomingActionParser()

    @Test(
        "A page on our domain that names no destination opens in the browser",
        arguments: [
            "https://tangem.com/some/page",
            "https://www.tangem.com/some/page",
            "https://app.tangem.com/anything",
            "https://buy.tangem.com/?promocode=PROMO",
            "https://tangem.surveysparrow.com/s/tangem-pay/tt-F8XXX",
            "https://feedback.tangem.com/anything",
        ]
    )
    func opensPagesInTheBrowser(urlString: String) throws {
        let url = try #require(URL(string: urlString))

        #expect(parser.parseIncomingURL(url) == .externalLink(url))
    }

    @Test(
        "A page that names a destination without what it needs opens in the browser",
        arguments: [
            "https://tangem.com/pay-app",
            "https://tangem.com/joint-account/join/invite!id",
            "https://tangem.com/news/markets/no-numeric-id",
        ]
    )
    func opensIncompletePagesInTheBrowser(urlString: String) throws {
        let url = try #require(URL(string: urlString))

        #expect(parser.parseIncomingURL(url) == .externalLink(url))
    }

    @Test(
        "A page that names a destination is not turned into a page",
        arguments: [
            "https://tangem.com/pay-app?id=something",
            "https://tangem.com/news/markets/190801-polygon-protiv-ethereum",
            "https://tangem.com/joint-account/join/B15CF4AC32F65CA583F007580390FAD07CF48A2BBD23C817A6FE83A3FF1BFB63",
        ]
    )
    func leavesDestinationsToTheirParser(urlString: String) throws {
        let url = try #require(URL(string: urlString))

        guard case .navigation = parser.parseIncomingURL(url) else {
            Issue.record("Expected a navigation action for \(urlString)")
            return
        }
    }

    /// Articles and invites live on the main domain only, so the same shape on another domain of ours is
    /// a page — the rule two destinations state and nothing else asserts.
    @Test(
        "A page of the right shape on another domain of ours is still a page",
        arguments: [
            "https://www.tangem.com/news/markets/190801-polygon-protiv-ethereum",
            "https://www.tangem.com/joint-account/join/B15CF4AC32F65CA583F007580390FAD07CF48A2BBD23C817A6FE83A3FF1BFB63",
        ]
    )
    func opensPagesOfOtherDomainsInTheBrowser(urlString: String) throws {
        let url = try #require(URL(string: urlString))

        #expect(parser.parseIncomingURL(url) == .externalLink(url))
    }

    /// The card's own link means «scan», so it must win over the page rule.
    @Test("The ndef link asks for a scan, not for a page")
    func ndefLinkAsksForScan() throws {
        let url = try #require(URL(string: "https://app.tangem.com/ndef"))

        #expect(parser.parseIncomingURL(url) == .start)
    }

    /// «Scan» is what the whole link means, not any link with `ndef` somewhere in it: a page that names a
    /// destination keeps it.
    @Test("A destination is not turned into a scan by an ndef further along the path")
    func ndefInsideAPathLeavesTheDestinationAlone() throws {
        let url = try #require(URL(string: "https://tangem.com/news/ndef/190801-polygon-protiv-ethereum"))

        #expect(parser.parseIncomingURL(url) == .navigation(.newsArticle(NewsArticleDeeplink(newsId: 190801, deeplinkString: url.absoluteString))))
    }

    /// The attribution domain is trusted as an origin so the links it serves are read, but it forwards
    /// rather than holds anything, so a link from it that names nothing is nothing.
    @Test(
        "A link from the attribution domain is never a page",
        arguments: [
            "https://tangem.onelink.me/abcd",
            "https://tangem.onelink.me/abcd?deep_link_value=something_else",
        ]
    )
    func attributionLinksAreNotPages(urlString: String) throws {
        let url = try #require(URL(string: urlString))

        #expect(parser.parseIncomingURL(url) == nil)
    }

    @Test(
        "A link outside our domains is not ours",
        arguments: [
            "https://tangeem.com/some/page",
            "https://app.google.com/anything",
            "http://tangem.com",
            "https://tangem.co/wallet",
            "https://apptangem.com/page",
            "https://wallet.tangem.com/redirect",
            "ftp://tangem.com/file",
        ]
    )
    func foreignLinksAreNotOurs(urlString: String) throws {
        let url = try #require(URL(string: urlString))

        #expect(parser.parseIncomingURL(url) == nil)
    }
}
