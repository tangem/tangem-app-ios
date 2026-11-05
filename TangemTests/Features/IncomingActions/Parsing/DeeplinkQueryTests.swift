//
//  DeeplinkQueryTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Deeplink query read once")
struct DeeplinkQueryTests {
    @Test(
        "A value decoded once keeps what a second decoding would change",
        arguments: [
            ("page=https%3A%2F%2Ftangem.com%2Fa%2520b", "https://tangem.com/a%20b"),
            ("page=100%25", "100%"),
            ("page=a%2Bb", "a+b"),
            ("page=a+b", "a+b"),
        ]
    )
    func readsValueDecodedOnce(query: String, expectedValue: String) throws {
        #expect(try makeSUT(query: query).decodedOnce(Constants.key) == expectedValue)
    }

    @Test(
        "The first value that isn't empty is the one read",
        arguments: ["page=&page=first&page=second", "page&page=first"]
    )
    func readsFirstNonEmptyValue(query: String) throws {
        #expect(try makeSUT(query: query).decodedOnce(Constants.key) == "first")
    }

    @Test(
        "A missing or empty value reads as absent",
        arguments: ["", "page=", "other=value"]
    )
    func readsAbsentValue(query: String) throws {
        #expect(try makeSUT(query: query).decodedOnce(Constants.key) == nil)
    }
}

// MARK: - Helpers

private extension DeeplinkQueryTests {
    enum Constants {
        static let key = "page"
    }

    func makeSUT(query: String) throws -> DeeplinkQuery {
        let url = try #require(URL(string: "tangem://promo_page?\(query)"))
        return DeeplinkQuery(url: url)
    }
}
