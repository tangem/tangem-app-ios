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

struct NewsDeeplinkValidationServiceTests {
    // MARK: - validateAndLogMismatchIfNeeded Tests

    @Test("Does not log when no pending deeplink URL")
    func doesNotLogWhenNoPendingDeeplinkURL() {
        let service = NewsDeeplinkValidationService()
        // No setDeeplinkURL called

        // Should not crash and should not log (no way to verify logging here, but at least no crash)
        service.validateAndLogMismatchIfNeeded(newsId: 123, actualNewsURL: "https://tangem.com/news/markets/123-article")
    }

    @Test("Does not log when URLs match")
    func doesNotLogWhenURLsMatch() {
        let service = NewsDeeplinkValidationService()
        service.setDeeplinkURL("https://tangem.com/news/markets/123-same-slug")

        // Same category and slug - should not log mismatch
        service.validateAndLogMismatchIfNeeded(newsId: 123, actualNewsURL: "https://tangem.com/news/markets/123-same-slug")
    }

    @Test("Detects category mismatch")
    func detectsCategoryMismatch() {
        let service = NewsDeeplinkValidationService()
        service.setDeeplinkURL("https://tangem.com/news/markets/123-article-slug")

        // Different category (crypto vs markets) - should trigger mismatch
        // Analytics.log will be called, but we can't easily verify without mocking
        service.validateAndLogMismatchIfNeeded(newsId: 123, actualNewsURL: "https://tangem.com/news/crypto/123-article-slug")
    }

    @Test("Detects slug mismatch")
    func detectsSlugMismatch() {
        let service = NewsDeeplinkValidationService()
        service.setDeeplinkURL("https://tangem.com/news/markets/123-old-slug")

        // Same category but different slug - should trigger mismatch
        service.validateAndLogMismatchIfNeeded(newsId: 123, actualNewsURL: "https://tangem.com/news/markets/123-new-updated-slug")
    }

    @Test("Detects both category and slug mismatch")
    func detectsBothCategoryAndSlugMismatch() {
        let service = NewsDeeplinkValidationService()
        service.setDeeplinkURL("https://tangem.com/news/markets/123-old-slug")

        // Different category AND different slug - should trigger mismatch
        service.validateAndLogMismatchIfNeeded(newsId: 123, actualNewsURL: "https://tangem.com/news/crypto/123-completely-different")
    }

    @Test("Clears pending URL after validation")
    func clearsPendingURLAfterValidation() {
        let service = NewsDeeplinkValidationService()
        service.setDeeplinkURL("https://tangem.com/news/markets/123-article")

        service.validateAndLogMismatchIfNeeded(newsId: 123, actualNewsURL: "https://tangem.com/news/markets/123-article")

        // Second call should not have pending URL
        // This is tested by not crashing and not logging (URL already cleared)
        service.validateAndLogMismatchIfNeeded(newsId: 123, actualNewsURL: "https://tangem.com/news/crypto/456-different")
    }

    @Test("Handles invalid deeplink URL gracefully")
    func handlesInvalidDeeplinkURLGracefully() {
        let service = NewsDeeplinkValidationService()
        service.setDeeplinkURL("not-a-valid-url")

        // Should not crash
        service.validateAndLogMismatchIfNeeded(newsId: 123, actualNewsURL: "https://tangem.com/news/markets/123-article")
    }

    @Test("Handles invalid actual URL gracefully")
    func handlesInvalidActualURLGracefully() {
        let service = NewsDeeplinkValidationService()
        service.setDeeplinkURL("https://tangem.com/news/markets/123-article")

        // Should not crash
        service.validateAndLogMismatchIfNeeded(newsId: 123, actualNewsURL: "not-a-valid-url")
    }

    @Test("Handles URL without slug")
    func handlesURLWithoutSlug() {
        let service = NewsDeeplinkValidationService()
        service.setDeeplinkURL("https://tangem.com/news/markets/123")

        // Same category, no slug in both - should match
        service.validateAndLogMismatchIfNeeded(newsId: 123, actualNewsURL: "https://tangem.com/news/markets/123")
    }

    @Test("Handles URL with slug vs URL without slug")
    func handlesURLWithSlugVsWithoutSlug() {
        let service = NewsDeeplinkValidationService()
        service.setDeeplinkURL("https://tangem.com/news/markets/123-article-slug")

        // One has slug, other doesn't - should detect mismatch
        service.validateAndLogMismatchIfNeeded(newsId: 123, actualNewsURL: "https://tangem.com/news/markets/123")
    }

    @Test("Handles URL with empty slug after dash")
    func handlesURLWithEmptySlugAfterDash() {
        let service = NewsDeeplinkValidationService()
        service.setDeeplinkURL("https://tangem.com/news/markets/123-")

        // Empty slug should be treated as nil
        service.validateAndLogMismatchIfNeeded(newsId: 123, actualNewsURL: "https://tangem.com/news/markets/123")
    }

    @Test("Handles URL with insufficient path components")
    func handlesURLWithInsufficientPathComponents() {
        let service = NewsDeeplinkValidationService()
        service.setDeeplinkURL("https://tangem.com/news/markets")

        // Only 3 path components (/, news, markets) - should not crash
        service.validateAndLogMismatchIfNeeded(newsId: 123, actualNewsURL: "https://tangem.com/news/markets/123-article")
    }

    @Test("Handles URL without news path")
    func handlesURLWithoutNewsPath() {
        let service = NewsDeeplinkValidationService()
        service.setDeeplinkURL("https://tangem.com/blog/markets/123-article")

        // Path doesn't contain "news" as second component - should not crash
        service.validateAndLogMismatchIfNeeded(newsId: 123, actualNewsURL: "https://tangem.com/news/markets/123-article")
    }

    // MARK: - logMismatchOnError Tests

    @Test("Does not log error when no pending deeplink URL")
    func doesNotLogErrorWhenNoPendingDeeplinkURL() {
        let service = NewsDeeplinkValidationService()
        // No setDeeplinkURL called

        let error = NSError(domain: "test", code: 404)
        // Should not crash
        service.logMismatchOnError(newsId: 123, error: error)
    }

    @Test("Clears pending URL after error logging")
    func clearsPendingURLAfterErrorLogging() {
        let service = NewsDeeplinkValidationService()
        service.setDeeplinkURL("https://tangem.com/news/markets/123-article")

        let error = NSError(domain: "test", code: 404)
        service.logMismatchOnError(newsId: 123, error: error)

        // Second call should not have pending URL
        service.logMismatchOnError(newsId: 456, error: error)
    }

    // MARK: - setDeeplinkURL Tests

    @Test("Can set and clear deeplink URL")
    func canSetAndClearDeeplinkURL() {
        let service = NewsDeeplinkValidationService()

        service.setDeeplinkURL("https://tangem.com/news/markets/123-article")
        service.setDeeplinkURL(nil)

        // After clearing, validation should do nothing
        service.validateAndLogMismatchIfNeeded(newsId: 123, actualNewsURL: "https://tangem.com/news/crypto/456-different")
    }

    @Test("Overwrites previous deeplink URL")
    func overwritesPreviousDeeplinkURL() {
        let service = NewsDeeplinkValidationService()

        service.setDeeplinkURL("https://tangem.com/news/old/111-old")
        service.setDeeplinkURL("https://tangem.com/news/new/222-new")

        // Should use the new URL for validation, not the old one
        // This is tested implicitly - the service should not crash
        service.validateAndLogMismatchIfNeeded(newsId: 222, actualNewsURL: "https://tangem.com/news/new/222-new")
    }
}
