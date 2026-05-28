//
//  RatingProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemTestKit
@testable import Tangem

@Suite("RatingProvider")
final class RatingProviderTests: LeakTrackingTestSuite {
    // MARK: - Check Existing Rating

    @Test("Returns nil when no existing rating")
    func returnsNilWhenNoRating() async throws {
        let spy = await makeSpy(checkResult: .success(nil))

        let result = try await spy.checkExisting(for: "tx123")

        #expect(result == nil)
        let checkCalls = await spy.checkCalls
        #expect(checkCalls.count == 1)
        #expect(checkCalls.first == "tx123")
    }

    @Test("Returns existing rating when found")
    func returnsExistingRating() async throws {
        let feedback = "Good service"
        let spy = await makeSpy(checkResult: .success(ExistingRating(rating: 4, feedback: feedback)))

        let result = try await spy.checkExisting(for: "tx456")

        #expect(result?.rating == 4)
        #expect(result?.feedback == feedback)
    }

    @Test("Returns rating without feedback")
    func returnsRatingWithoutFeedback() async throws {
        let spy = await makeSpy(checkResult: .success(ExistingRating(rating: 5, feedback: nil)))

        let result = try await spy.checkExisting(for: "tx789")

        #expect(result?.rating == 5)
        #expect(result?.feedback == nil)
    }

    @Test("Throws error on network failure during check")
    func throwsOnCheckNetworkFailure() async {
        let error = SurveySparrowRatingProvider.Error.networkError(URLError(.notConnectedToInternet))
        let spy = await makeSpy(checkResult: .failure(error))

        await #expect(throws: SurveySparrowRatingProvider.Error.self) {
            try await spy.checkExisting(for: "tx_fail")
        }
    }

    @Test("Throws error on 401 unauthorized")
    func throwsOnUnauthorized() async {
        let spy = await makeSpy(checkResult: .failure(SurveySparrowRatingProvider.Error.httpError(401)))

        await #expect(throws: SurveySparrowRatingProvider.Error.self) {
            try await spy.checkExisting(for: "tx_401")
        }
    }

    @Test("Throws error on 500 server error")
    func throwsOnServerError() async {
        let spy = await makeSpy(checkResult: .failure(SurveySparrowRatingProvider.Error.httpError(500)))

        await #expect(throws: SurveySparrowRatingProvider.Error.self) {
            try await spy.checkExisting(for: "tx_500")
        }
    }

    @Test("Throws error on malformed JSON")
    func throwsOnMalformedJSON() async {
        let spy = await makeSpy(checkResult: .failure(SurveySparrowRatingProvider.Error.decodingError))

        await #expect(throws: SurveySparrowRatingProvider.Error.self) {
            try await spy.checkExisting(for: "tx_bad_json")
        }
    }

    // MARK: - Submit Rating

    @Test("Submits rating successfully")
    func submitsRatingSuccessfully() async throws {
        let spy = await makeSpy(submitResult: .success(()))
        let feedback = "Great!"
        let provider = "ChangeNOW"

        try await spy.submit(request: makeRequest(feedback: feedback, provider: provider))

        let submitCalls = await spy.submitCalls
        #expect(submitCalls.count == 1)
        #expect(submitCalls.first?.feedback == feedback)
        #expect(submitCalls.first?.provider == provider)
    }

    @Test("Submits rating without feedback")
    func submitsWithoutFeedback() async throws {
        let spy = await makeSpy(submitResult: .success(()))

        try await spy.submit(request: makeRequest(rating: 5))

        #expect(await spy.submitCalls.first?.feedback == nil)
    }

    @Test("Throws error on network failure during submit")
    func throwsOnSubmitNetworkFailure() async {
        let error = SurveySparrowRatingProvider.Error.networkError(URLError(.timedOut))
        let spy = await makeSpy(submitResult: .failure(error))

        await #expect(throws: SurveySparrowRatingProvider.Error.self) {
            try await spy.submit(request: makeRequest())
        }
    }

    @Test("Throws error on 401 during submit")
    func throwsOnSubmitUnauthorized() async {
        let spy = await makeSpy(submitResult: .failure(SurveySparrowRatingProvider.Error.httpError(401)))

        await #expect(throws: SurveySparrowRatingProvider.Error.self) {
            try await spy.submit(request: makeRequest())
        }
    }

    @Test("Throws error on 429 rate limit")
    func throwsOnRateLimit() async {
        let spy = await makeSpy(submitResult: .failure(SurveySparrowRatingProvider.Error.httpError(429)))

        await #expect(throws: SurveySparrowRatingProvider.Error.self) {
            try await spy.submit(request: makeRequest())
        }
    }

    @Test("Builds correct request with all fields")
    func buildsCorrectRequest() async throws {
        let spy = await makeSpy(submitResult: .success(()))
        let transactionId = "tx_full"
        let rating = 3
        let feedback = "Feedback with emoji 🚀 and special <chars>"
        let provider = "ChangeNOW"

        try await spy.submit(request: makeRequest(
            transactionId: transactionId,
            rating: rating,
            feedback: feedback,
            provider: provider
        ))

        let submitted = await spy.submitCalls.first
        #expect(submitted?.transactionId == transactionId)
        #expect(submitted?.rating == rating)
        #expect(submitted?.feedback == feedback)
        #expect(submitted?.provider == provider)
    }
}

// MARK: - Helpers

private extension RatingProviderTests {
    func makeSpy(
        checkResult: Result<ExistingRating?, Error> = .success(nil),
        submitResult: Result<Void, Error> = .success(())
    ) async -> RatingProviderSpy {
        let spy = RatingProviderSpy()
        await spy.setCheckResult(checkResult)
        await spy.setSubmitResult(submitResult)
        return trackForMemoryLeaks(spy)
    }

    func makeRequest(
        transactionId: String = "tx_test",
        rating: Int = 4,
        feedback: String? = nil,
        provider: String = "TestProvider",
        userWalletIdHash: String = "test_wallet_hash",
        txUrl: String? = "https://example.com/tx"
    ) -> RatingRequest {
        RatingRequest(
            transactionId: transactionId,
            rating: rating,
            feedback: feedback,
            provider: provider,
            userWalletIdHash: userWalletIdHash,
            txUrl: txUrl
        )
    }
}
