//
//  MainQRParserSupportTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("MainQRParserSupport")
struct MainQRParserSupportTests {
    // MARK: - queryItems

    @Test("Extracts query items located after the '?' separator")
    func queryItemsFromValue() {
        let items = MainQRParserSupport.queryItems(from: "scheme:addr?amount=1.5&memo=hi")

        #expect(items.count == 2)
        #expect(MainQRParserSupport.firstQueryValue(in: items, names: ["amount"]) == "1.5")
        #expect(MainQRParserSupport.firstQueryValue(in: items, names: ["memo"]) == "hi")
    }

    @Test("Returns an empty array when there is no query separator")
    func queryItemsNoSeparator() {
        #expect(MainQRParserSupport.queryItems(from: "scheme:addr").isEmpty)
    }

    @Test("Lowercases keys and percent-decodes values")
    func queryItemsNormalization() {
        let items = MainQRParserSupport.queryItems(fromRawQuery: "Memo=hello%20world&ADDRESS=0xAbC")

        // Keys are normalized to lowercase; the value is percent-decoded but otherwise preserved.
        #expect(MainQRParserSupport.firstQueryValue(in: items, names: ["memo"]) == "hello world")
        #expect(MainQRParserSupport.firstQueryValue(in: items, names: ["address"]) == "0xAbC")
    }

    @Test("Keeps a flag without a value as nil")
    func queryItemsFlagWithoutValue() {
        let items = MainQRParserSupport.queryItems(fromRawQuery: "flag")

        #expect(items.count == 1)
        #expect(items.first?.name == "flag")
        #expect(items.first?.value == nil)
    }

    @Test("Keeps an empty value as an empty string")
    func queryItemsEmptyValue() {
        let items = MainQRParserSupport.queryItems(fromRawQuery: "key=")

        #expect(items.first?.value == "")
    }

    // MARK: - firstQueryValue

    @Test("Returns the first item whose normalized name is in the requested set")
    func firstQueryValueMatch() {
        let items = [
            URLQueryItem(name: "value", value: "10"),
            URLQueryItem(name: "amount", value: "20"),
        ]

        #expect(MainQRParserSupport.firstQueryValue(in: items, names: ["amount", "value"]) == "10")
        #expect(MainQRParserSupport.firstQueryValue(in: items, names: ["AMOUNT"]) == "20")
        #expect(MainQRParserSupport.firstQueryValue(in: items, names: ["memo"]) == nil)
    }

    // MARK: - firstPayloadString

    @Test("Returns the first string-typed payload value, skipping non-string values")
    func firstPayloadString() {
        let payload: [String: Any] = ["amount": "1.5", "value": 10]

        // `value` exists but is an Int, so it is skipped in favor of the string `amount`.
        #expect(MainQRParserSupport.firstPayloadString(in: payload, keys: ["value", "amount"]) == "1.5")
        #expect(MainQRParserSupport.firstPayloadString(in: payload, keys: ["missing"]) == nil)
    }

    // MARK: - normalization

    @Test("Lowercases identifiers and strips '-', '_' and spaces")
    func normalizeIdentifier() {
        #expect(MainQRParserSupport.normalizeIdentifier("Hello-World_Foo Bar") == "helloworldfoobar")
        #expect(MainQRParserSupport.normalizeIdentifier("USDT") == "usdt")
    }

    @Test("Lowercases query keys")
    func normalizeQueryKey() {
        #expect(MainQRParserSupport.normalizeQueryKey("Amount") == "amount")
    }

    // MARK: - hasPrefix

    @Test("Matches prefixes case-insensitively")
    func hasPrefix() {
        #expect(MainQRParserSupport.hasPrefix("Ethereum:0x123", in: ["ethereum:"]))
        #expect(MainQRParserSupport.hasPrefix("bitcoin:abc", in: ["ethereum:", "bitcoin:"]))
        #expect(!MainQRParserSupport.hasPrefix("tron:abc", in: ["ethereum:", "bitcoin:"]))
    }

    // MARK: - unknownParameters

    @Test("Collects only the parameters that are not in the known set")
    func unknownParameters() {
        let items = [
            URLQueryItem(name: "amount", value: "1"),
            URLQueryItem(name: "foo", value: "bar"),
            URLQueryItem(name: "flag", value: nil),
        ]

        // `amount` is known, `flag` has no value, so only `foo` remains.
        let unknown = MainQRParserSupport.unknownParameters(in: items, knownKeys: ["amount"])

        #expect(unknown == ["foo": "bar"])
    }

    // MARK: - stripEthereumSchemePrefix

    @Test("Strips the ethereum scheme prefix, returns nil for other schemes")
    func stripEthereumSchemePrefix() {
        #expect(MainQRParserSupport.stripEthereumSchemePrefix(from: "ethereum:0xABC") == "0xABC")
        #expect(MainQRParserSupport.stripEthereumSchemePrefix(from: "bitcoin:abc") == nil)
    }
}
