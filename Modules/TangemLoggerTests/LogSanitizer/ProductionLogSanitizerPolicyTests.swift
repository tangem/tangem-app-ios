//
//  ProductionLogSanitizerPolicyTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import TangemLogger

@Suite(.tags(.logSanitizer))
struct ProductionLogSanitizerPolicyTests {
    @Test
    func shouldPreserveMultipleSafeValuesInSingleLog() {
        let input = #"response: <NSHTTPURLResponse: 0x106f3a120>;"#
            + #"start="2026-12-24T00:00:00.000Z";"#
            + #"end="1970-01-01T12:34:56Z""#

        let actual = LogSanitizer.sanitize(input, policy: .production)
        #expect(actual == input)
    }

    @Test
    func shouldRedactSensitiveValuesWithoutAffectingPreservedValues() {
        let input = #"response: <NSHTTPURLResponse: 0x106f3a120>; timestamp="2026-12-24T00:00:00.000Z"; "#
            + #"headers: ["api-key": "secret123", "access-token": "abc/def=="]"#

        let expected = #"response: <NSHTTPURLResponse: 0x106f3a120>; timestamp="2026-12-24T00:00:00.000Z"; "#
            + #"headers: ["api-key": "\#(Self.sensitiveKeyRedactPlaceholder)", "#
            + #""access-token": "\#(Self.sensitiveKeyRedactPlaceholder)"]"#

        let actual = LogSanitizer.sanitize(input, policy: .production)

        #expect(actual == expected)
    }

    @Test
    func shouldBeIdempotent() {
        let input = #"response: <NSHTTPURLResponse: 0x106f3a120>; "#
            + #"timestamp="2026-12-24T00:00:00.000Z"; "#
            + #"headers: ["api-key": "secret123"]; hex=0xdeadbeef"#

        let firstPass = LogSanitizer.sanitize(input, policy: .production)
        let secondPass = LogSanitizer.sanitize(firstPass, policy: .production)

        #expect(firstPass == secondPass)
    }

    @Test
    func shouldLeaveSafeLogUnchanged() {
        let input = #"response: success; status=200; message="everything is fine""#
        let actual = LogSanitizer.sanitize(input, policy: .production)

        #expect(actual == input)
    }

    @Test
    func shouldRedactMultipleSensitiveKeysInSingleLog() {
        let input = "key=abcd1234abcd5678abcd&auth=1234abcd1234abcd1234"
        let expected = "key=\(Self.sensitiveKeyRedactPlaceholder)&auth=\(Self.sensitiveKeyRedactPlaceholder)"

        let actual = LogSanitizer.sanitize(input, policy: .production)

        #expect(actual == expected)
    }

    @Test
    func shouldRedactSensitiveKeyInsideJsonPayload() {
        let input = #"{"key": "abcd1234abcd5678abcd"}"#
        let expected = #"{"key": "\#(Self.sensitiveKeyRedactPlaceholder)"}"#

        let actual = LogSanitizer.sanitize(input, policy: .production)

        #expect(actual == expected)
    }

    @Test
    func shouldRedactSensitiveKeyAndBroadHexInSingleLog() {
        let input = "x-api-key=abcd1234abcd5678abcd hex=deadbeefcafebabe"
        let expected = "x-api-key=\(Self.sensitiveKeyRedactPlaceholder) hex=\(Self.broadHexRedactPlaceholder)"

        let actual = LogSanitizer.sanitize(input, policy: .production)

        #expect(actual == expected)
    }

    @Test
    func shouldRedactKeysAndBroadHexInNetworkRequestLog() {
        let input = """
        🟠 request: https://api.tangem.org/card/artworks¸
           headers: [
             "card_public_key": "7C2A9F1E4D6B8C3F0A5E7D1B9C4F2A6E8B1D3C7F5A9E0C2B6D4F8A1E3C5B7D9"¸
             "card_id": "C91B0000002A7E4F"¸
             "device": "iPhone 69"¸
             "platform": "ios"¸
             "system_version": "42.0"¸
             "language": "en-GB"¸
             "version": "6.7"¸
             "api-key": "kR9vTqLmP4xZc8Hs2NwJfYgD7UaB3eQi6XpMoK1rCzVtEyL5hSnFu0WbAjIGdORXl"¸
             "Content-Type": "application/json"¸
             "timezone": "Asia/Bangkok"
           ]
        """

        let expected = """
        🟠 request: https://api.tangem.org/card/artworks¸
           headers: [
             "card_public_key": "\(Self.sensitiveKeyRedactPlaceholder)"¸
             "card_id": "\(Self.broadHexRedactPlaceholder)"¸
             "device": "iPhone 69"¸
             "platform": "ios"¸
             "system_version": "42.0"¸
             "language": "en-GB"¸
             "version": "6.7"¸
             "api-key": "\(Self.sensitiveKeyRedactPlaceholder)"¸
             "Content-Type": "application/json"¸
             "timezone": "Asia/Bangkok"
           ]
        """

        let actual = LogSanitizer.sanitize(input, policy: .production)

        #expect(actual == expected)
    }
}

extension ProductionLogSanitizerPolicyTests {
    private static let sensitiveKeyRedactPlaceholder = "REDACTED_SENSITIVE_KEY"
    private static let broadHexRedactPlaceholder = "REDACTED_HEX"
}
