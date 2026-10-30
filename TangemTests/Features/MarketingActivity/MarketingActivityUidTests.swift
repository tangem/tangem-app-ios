//
//  MarketingActivityUidTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("MarketingActivityUid")
struct MarketingActivityUidTests {
    @Test(
        "The uid is read as the link carries it, decoded once",
        arguments: [
            ("tangem://markets?uid=AbC-123", "AbC-123"),
            ("tangem://markets?order=rating&uid=AbC-123&interval=1w", "AbC-123"),
            ("tangem://markets?uid=%20AbC%20", " AbC "),
            ("tangem://markets?uid=a%2Fb", "a/b"),
            ("tangem://markets?uid=100%25", "100%"),
            ("tangem://markets?uid=a+b", "a+b"),
            ("tangem://markets?uid=first&uid=second", "first"),
            ("tangem://markets?uid=&uid=second", "second"),
            ("tangem://markets?uid&uid=second", "second"),
            ("https://tangem.com/pay-app?id=1&uid=AbC-123", "AbC-123"),
        ]
    )
    func readsUid(link: String, expectedUid: String) throws {
        let url = try #require(URL(string: link))

        #expect(MarketingActivityUid.read(from: url) == expectedUid)
    }

    @Test(
        "A link without a uid, or with an empty one, carries none",
        arguments: [
            "tangem://markets",
            "tangem://markets?uid=",
            "tangem://markets?uid",
            "tangem://markets?UID=AbC-123",
        ]
    )
    func noUid(link: String) throws {
        let url = try #require(URL(string: link))

        #expect(MarketingActivityUid.read(from: url) == nil)
    }

    @Test(
        "A link written to the log carries its uid masked and the rest as it was",
        arguments: [
            ("tangem://markets?uid=AbC-123", "tangem://markets?uid=***"),
            ("tangem://markets?order=rating&uid=AbCdEfGh12&interval=1w", "tangem://markets?order=rating&uid=Ab...12&interval=1w"),
            ("tangem://markets?uid=first&uid=second", "tangem://markets?uid=***&uid=***"),
            ("tangem://markets?order=a%2Fb&q=a+b&uid=AbC-123", "tangem://markets?order=a%2Fb&q=a+b&uid=***"),
            ("tangem://markets?uid=%26%3DAbCdEfGh", "tangem://markets?uid=%26%3D...Gh"),
            ("tangem://markets?uid=&order=rating", "tangem://markets?uid=&order=rating"),
            ("tangem://markets?order=rating", "tangem://markets?order=rating"),
        ]
    )
    func loggableLink(link: String, expectedLink: String) throws {
        let url = try #require(URL(string: link))

        #expect(MarketingActivityUid.loggableLink(url) == expectedLink)
    }

    @Test(
        "A link kept as text is masked the same way",
        arguments: [
            ("https://tangem.com/news/markets/190801-polygon?uid=AbCdEfGh12", "https://tangem.com/news/markets/190801-polygon?uid=Ab...12"),
            ("https://tangem.com/news/markets/190801-polygon", "https://tangem.com/news/markets/190801-polygon"),
        ]
    )
    func loggableLinkFromText(link: String, expectedLink: String) {
        #expect(MarketingActivityUid.loggableLink(link) == expectedLink)
    }
}
