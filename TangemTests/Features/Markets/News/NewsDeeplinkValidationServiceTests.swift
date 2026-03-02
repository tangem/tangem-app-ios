//
//  NewsDeeplinkValidationServiceTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite(.tags(.news))
struct NewsDeeplinkValidationServiceTests {
    // MARK: - validateAndLogMismatchIfNeeded Tests

    @Test("Does not log when no pending deeplink URL")
    func doesNotLogWhenNoPendingDeeplinkURL() {
        let service = NewsDeeplinkValidationService()

        let hasMismatch = service.validateAndLogMismatchIfNeeded(
            newsId: 123,
            actualNewsURL: "https://tangem.com/news/markets/123-article"
        )

        #expect(hasMismatch == false)
    }

    @Test("Validates deeplink URL variations", arguments: Self.validationCases())
    func validatesDeeplinkURLVariations(
        caseName: String,
        deeplinkURL: String,
        actualURL: String,
        expectedMismatch: Bool
    ) {
        let service = NewsDeeplinkValidationService()
        service.setDeeplinkURL(deeplinkURL)

        let hasMismatch = service.validateAndLogMismatchIfNeeded(newsId: 123, actualNewsURL: actualURL)

        #expect(hasMismatch == expectedMismatch, "Case: \(caseName)")
    }

    private static func validationCases() -> [(String, String, String, Bool)] {
        [
            ("URLs match", "https://tangem.com/news/markets/123-same-slug", "https://tangem.com/news/markets/123-same-slug", false),
            ("Category mismatch", "https://tangem.com/news/markets/123-article-slug", "https://tangem.com/news/crypto/123-article-slug", true),
            ("Slug mismatch", "https://tangem.com/news/markets/123-old-slug", "https://tangem.com/news/markets/123-new-updated-slug", true),
            ("Category and slug mismatch", "https://tangem.com/news/markets/123-old-slug", "https://tangem.com/news/crypto/123-completely-different", true),
            ("Invalid deeplink URL", "not-a-valid-url", "https://tangem.com/news/markets/123-article", false),
            ("Invalid actual URL", "https://tangem.com/news/markets/123-article", "not-a-valid-url", false),
            ("URL without slug", "https://tangem.com/news/markets/123", "https://tangem.com/news/markets/123", false),
            ("Slug vs no slug", "https://tangem.com/news/markets/123-article-slug", "https://tangem.com/news/markets/123", true),
            ("Empty slug after dash", "https://tangem.com/news/markets/123-", "https://tangem.com/news/markets/123", false),
            ("Insufficient path components", "https://tangem.com/news/markets", "https://tangem.com/news/markets/123-article", false),
            ("URL without news path", "https://tangem.com/blog/markets/123-article", "https://tangem.com/news/markets/123-article", false),
        ]
    }

    @Test("Clears pending URL after validation")
    func clearsPendingURLAfterValidation() {
        let service = NewsDeeplinkValidationService()
        service.setDeeplinkURL("https://tangem.com/news/markets/123-article")

        let firstResult = service.validateAndLogMismatchIfNeeded(
            newsId: 123,
            actualNewsURL: "https://tangem.com/news/markets/123-article"
        )
        #expect(firstResult == false)

        let secondResult = service.validateAndLogMismatchIfNeeded(
            newsId: 123,
            actualNewsURL: "https://tangem.com/news/crypto/456-different"
        )
        #expect(secondResult == false)
    }

    // MARK: - logMismatchOnError Tests

    @Test("Does not log error when no pending deeplink URL")
    func doesNotLogErrorWhenNoPendingDeeplinkURL() {
        let service = NewsDeeplinkValidationService()

        let error = NSError(domain: "test", code: 404)
        let didLog = service.logMismatchOnError(newsId: 123, error: error)
        #expect(didLog == false)
    }

    @Test("Clears pending URL after error logging")
    func clearsPendingURLAfterErrorLogging() {
        let service = NewsDeeplinkValidationService()
        service.setDeeplinkURL("https://tangem.com/news/markets/123-article")

        let error = NSError(domain: "test", code: 404)
        let firstLogResult = service.logMismatchOnError(newsId: 123, error: error)
        #expect(firstLogResult == true)

        let secondLogResult = service.logMismatchOnError(newsId: 456, error: error)
        #expect(secondLogResult == false)
    }

    // MARK: - setDeeplinkURL Tests

    @Test("Can set and clear deeplink URL")
    func canSetAndClearDeeplinkURL() {
        let service = NewsDeeplinkValidationService()

        service.setDeeplinkURL("https://tangem.com/news/markets/123-article")
        service.setDeeplinkURL(nil)

        let result = service.validateAndLogMismatchIfNeeded(
            newsId: 123,
            actualNewsURL: "https://tangem.com/news/crypto/456-different"
        )
        #expect(result == false)
    }

    @Test("Overwrites previous deeplink URL")
    func overwritesPreviousDeeplinkURL() {
        let service = NewsDeeplinkValidationService()

        service.setDeeplinkURL("https://tangem.com/news/old/111-old")
        service.setDeeplinkURL("https://tangem.com/news/new/222-new")

        let mismatchForNew = service.validateAndLogMismatchIfNeeded(
            newsId: 222,
            actualNewsURL: "https://tangem.com/news/new/222-new"
        )
        #expect(mismatchForNew == false)
    }
}
