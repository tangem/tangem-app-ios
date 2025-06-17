//
//  LogsSanitizerTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Testing
@testable import TangemLogger

@Suite("LogsSanitizer")
struct LogsSanitizerTests {
    // MARK: - API Key Redaction

    @Test(arguments: LogsSanitizer.apiKeyFields)
    func messageHasAPIKey_thenRedacts(key: String) {
        let input = "\(key)=abcd1234abcd5678abcd"
        let expected = "\(key)=REDACTED"
        #expect(LogsSanitizer.sanitize(input) == expected)
    }

    @Test(arguments: [
        "   abcd1234abcd5678abcd",
        "\"abcd1234abcd5678abcd\"",
        "'abcd1234abcd5678abcd'"
    ])
    func messageHasAPIKeyValue_thenRedacts(apiKeyValue: String) {
        let input = "token: \(apiKeyValue)"
        let expected = "token=REDACTED"
        #expect(LogsSanitizer.sanitize(input) == expected)
    }

    @Test
    func messageHasQueryStringApiKey_thenRedacts() {
        let input = "https://example.com?api_key=abcd1234abcd5678abcd"
        let expected = "https://example.com?api_key=REDACTED"
        #expect(LogsSanitizer.sanitize(input) == expected)
    }

    @Test
    func messageHasMultipleKeysInOneLine_thenRedact() {
        let input = "token=abcd1234abcd5678abcd&auth=1234abcd1234abcd1234"
        let expected = "token=REDACTED&auth=REDACTED"
        #expect(LogsSanitizer.sanitize(input) == expected)
    }

    @Test
    func messageHasKeyInJSONBody_thenRedacts() {
        let input = #"{"key": "abcd1234abcd5678abcd"}"#
        let expected = #"{"key": "REDACTED"}"#
        #expect(LogsSanitizer.sanitize(input) == expected)
    }

    // MARK: - HEX Data Redaction

    @Test(arguments: [
        "dead-beef-cafe-babe",
        "0xdead-beef-cafe-babe",
        "0XaA-Bb-Cc-Dd-Ee-Ff",
        "A1B2C3D4E5F6",
        "deadbeefcafebabe"
    ])
    func messageHasCommonPlainHexes_thenRedacts(hex: String) {
        let expected = "REDACTED"
        #expect(LogsSanitizer.sanitize(hex) == expected)
    }

    @Test
    func messageHasMultipleHexes_thenRedactsAll() {
        let input = "Values: 12345678 and ABCDEF12 and cafe9876"
        let expected = "Values: REDACTED and REDACTED and REDACTED"
        #expect(LogsSanitizer.sanitize(input) == expected)
    }

    @Test
    func messageIsHexSeparatedBySpaces_thenRedactsWithMultiplePlaceholders() {
        let input = "Chunks: DEADBEEF CAFEBABE F00DBABE"
        let expected = "Chunks: REDACTED REDACTED REDACTED"
        #expect(LogsSanitizer.sanitize(input) == expected)
    }

    // MARK: - Mixed

    @Test
    func messageIsMixedApiKeyAndHex_thenRedacts() {
        let input = "token=abcd1234abcd5678abcd hex=deadbeefcafebabe"
        let expected = "token=REDACTED hex=REDACTED"
        #expect(LogsSanitizer.sanitize(input) == expected)
    }

    @Test
    func messageHasNoSensitiveData_thenDoesNotRedact() {
        let input = "Normal log message without secrets"
        #expect(LogsSanitizer.sanitize(input) == input)
    }

    @Test
    func messageIsHexWithBoundaries_thenRedacts() {
        let input = "[dead-beef-cafe-babe]"
        let expected = "[REDACTED]"
        #expect(LogsSanitizer.sanitize(input) == expected)
    }
}
