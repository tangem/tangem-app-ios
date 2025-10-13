//
//  HostSanitizerUtilTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemFoundation
@testable import Tangem

final class HostSanitizerUtilTests: XCTestCase {
    private var sut: HostSanitizerUtil!

    override func setUp() {
        super.setUp()
        sut = HostSanitizerUtil()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - URL Sanitization Tests

    func testSanitizeSimpleHTTPSURL() {
        // Given
        let input = "https://api.example.com"

        // When
        let result = sut.sanitizedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_api_example_com")
    }

    func testSanitizeHTTPURL() {
        // Given
        let input = "http://api.example.com"

        // When
        let result = sut.sanitizedHost(from: input)

        // Then
        XCTAssertEqual(result, "http_api_example_com")
    }

    func testSanitizeURLWithPort() {
        // Given
        let input = "https://api.example.com:8080"

        // When
        let result = sut.sanitizedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_api_example_com_8080")
    }

    func testSanitizeURLWithPathComponents() {
        // Given
        let input = "https://api.example.com/v1/users"

        // When
        let result = sut.sanitizedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_api_example_com_v1_users")
    }

    func testSanitizeURLWithAPIKeyInPath() {
        // Given
        let input = "https://api.example.com/v1/abcdef1234567890KEYSECRET123456"

        // When
        let result = sut.sanitizedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_api_example_com_v1_***")
    }

    func testSanitizeURLWithMultiplePathComponentsAndAPIKey() {
        // Given
        let input = "https://api.example.com/v1/endpoint/abc123def456ghi789jkl012"

        // When
        let result = sut.sanitizedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_api_example_com_v1_endpoint_***")
    }

    func testSanitizeURLWithMixedPathComponents() {
        // Given
        let input = "https://api.example.com/v1/short/verylongapikeystring1234567890abc/end"

        // When
        let result = sut.sanitizedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_api_example_com_v1_short_***_end")
    }

    func testSanitizeURLWithPortAndPath() {
        // Given
        let input = "https://api.example.com:9000/v1/data"

        // When
        let result = sut.sanitizedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_api_example_com_9000_v1_data")
    }

    // MARK: - Hostname Sanitization Tests

    func testSanitizeSimpleHostname() {
        // Given
        let input = "api.example.com"

        // When
        let result = sut.sanitizedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_api_example_com")
    }

    func testSanitizeHostnameWithSubdomains() {
        // Given
        let input = "sub.api.example.com"

        // When
        let result = sut.sanitizedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_sub_api_example_com")
    }

    func testSanitizeHostnameWithoutDots() {
        // Given
        let input = "localhost"

        // When
        let result = sut.sanitizedHost(from: input)

        // Then
        XCTAssertEqual(result, "localhost")
    }

    func testSanitizeHostnameAlreadyWithHTTPPrefix() {
        // Given
        let input = "http_api_example_com"

        // When
        let result = sut.sanitizedHost(from: input)

        // Then
        XCTAssertEqual(result, "http_api_example_com")
    }

    // MARK: - Case Sensitivity Tests

    func testSanitizeURLWithUppercaseCharacters() {
        // Given
        let input = "HTTPS://API.EXAMPLE.COM/V1/Users"

        // When
        let result = sut.sanitizedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_api_example_com_v1_users")
    }

    func testSanitizeHostnameWithUppercaseCharacters() {
        // Given
        let input = "API.EXAMPLE.COM"

        // When
        let result = sut.sanitizedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_api_example_com")
    }

    // MARK: - API Key Detection Tests

    func testAPIKeyDetectionWithExactly20Characters() {
        // Given
        let input = "https://api.example.com/12345678901234567890"

        // When
        let result = sut.sanitizedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_api_example_com_***")
    }

    func testAPIKeyDetectionWithLessThan20Characters() {
        // Given
        let input = "https://api.example.com/1234567890123456789"

        // When
        let result = sut.sanitizedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_api_example_com_1234567890123456789")
    }

    func testAPIKeyDetectionWithDashesAndUnderscores() {
        // Given
        let input = "https://api.example.com/abc-def_ghi-123456789"

        // When
        let result = sut.sanitizedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_api_example_com_***")
    }

    func testAPIKeyDetectionWithSpecialCharacters() {
        // Given - 20+ chars but has special characters that shouldn't be in API key
        let input = "https://api.example.com/abcdef@1234567890123"

        // When
        let result = sut.sanitizedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_api_example_com_abcdef@1234567890123")
    }

    func testAPIKeyDetectionWithSlashes() {
        // Given - 20+ chars but has slashes
        let input = "https://api.example.com/abc/def/ghi/jkl/mno/pqr"

        // When
        let result = sut.sanitizedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_api_example_com_abc_def_ghi_jkl_mno_pqr")
    }

    // MARK: - Edge Cases

    func testSanitizeEmptyString() {
        // Given
        let input = ""

        // When
        let result = sut.sanitizedHost(from: input)

        // Then
        XCTAssertEqual(result, "")
    }

    func testSanitizeURLWithOnlyScheme() {
        // Given
        let input = "https://"

        // When
        let result = sut.sanitizedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_")
    }

    func testSanitizeIPAddress() {
        // Given
        let input = "192.168.1.1"

        // When
        let result = sut.sanitizedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_192_168_1_1")
    }

    func testSanitizeIPAddressWithScheme() {
        // Given
        let input = "http://192.168.1.1:8080"

        // When
        let result = sut.sanitizedHost(from: input)

        // Then
        XCTAssertEqual(result, "http_192_168_1_1_8080")
    }

    func testSanitizeURLWithTrailingSlash() {
        // Given
        let input = "https://api.example.com/"

        // When
        let result = sut.sanitizedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_api_example_com")
    }

    func testSanitizeComplexRealWorldURL() {
        // Given
        let input = "https://mainnet.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161"

        // When
        let result = sut.sanitizedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_mainnet_infura_io_v3_***")
    }

    func testSanitizeURLWithQueryParameters() {
        // Given
        let input = "https://api.example.com/v1/data?key=abcd1234efgh5678ijkl"

        // When
        let result = sut.sanitizedHost(from: input)

        // Then
        // Note: URL parsing treats query parameters separately from path
        XCTAssertEqual(result, "https_api_example_com_v1_data")
    }
}
