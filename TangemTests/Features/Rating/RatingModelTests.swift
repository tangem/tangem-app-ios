//
//  RatingModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemTestKit
@testable import Tangem

@Suite("RatingModel")
final class RatingModelTests: LeakTrackingTestSuite {
    typealias Rating = RatingModel.Rating

    // MARK: - Check Existing Rating

    @Test("Returns nil when not previously rated")
    func returnsNil() async throws {
        let (sut, _) = await makeSUT(checkResult: .success(nil))

        let result = try await sut.checkExisting()

        #expect(result == nil)
    }

    @Test("Returns existing rating when previously rated")
    func returnsExistingRating() async throws {
        let rating = 4
        let (sut, _) = await makeSUT(checkResult: .success(ExistingRating(rating: rating, feedback: "Good")))

        let result = try await sut.checkExisting()

        #expect(result == rating)
    }

    @Test("Passes transactionId to API service")
    func passesTransactionIdToAPI() async throws {
        let transactionId = "tx_check_123"
        let (sut, spy) = await makeSUT(checkResult: .success(nil), transactionId: transactionId)

        _ = try await sut.checkExisting()

        #expect(await spy.checkCalls.count == 1)
        #expect(await spy.checkCalls.first == transactionId)
    }

    @Test("Throws when check fails")
    func throwsOnCheckFailure() async {
        let (sut, _) = await makeSUT(checkResult: .failure(URLError(.notConnectedToInternet)))

        await #expect(throws: Error.self) {
            try await sut.checkExisting()
        }
    }

    // MARK: - Submit Rating

    @Test("Submits rating and returns success")
    func submitsRatingSuccessfully() async throws {
        let rating: Rating = .four
        let feedback = "Great!"
        let (sut, spy) = await makeSUT()

        let result = try await sut.submit(rating, feedback: feedback)

        #expect(result == .success)
        let submitCalls = await spy.submitCalls
        #expect(submitCalls.count == 1)
        #expect(submitCalls.first?.rating == rating.rawValue)
        #expect(submitCalls.first?.feedback == feedback)
    }

    @Test("Passes transactionId and provider to API service")
    func passesTransactionIdAndProviderToAPI() async throws {
        let transactionId = "tx_submit_456"
        let provider = "ChangeNOW"
        let (sut, spy) = await makeSUT(transactionId: transactionId, provider: provider)

        _ = try await sut.submit(.four, feedback: nil)

        let submitCalls = await spy.submitCalls
        #expect(submitCalls.first?.transactionId == transactionId)
        #expect(submitCalls.first?.provider == provider)
    }

    @Test("Passes userWalletIdHash and txUrl to API service")
    func passesUserWalletIdHashAndTxUrlToAPI() async throws {
        let userWalletIdHash = "abc123hash"
        let txUrl = "https://provider.com/tx/456"
        let (sut, spy) = await makeSUT(userWalletIdHash: userWalletIdHash, txUrl: txUrl)

        _ = try await sut.submit(.four, feedback: nil)

        let submitCalls = await spy.submitCalls
        #expect(submitCalls.first?.userWalletIdHash == userWalletIdHash)
        #expect(submitCalls.first?.txUrl == txUrl)
    }

    @Test("Passes nil txUrl when not provided")
    func passesNilTxUrl() async throws {
        let (sut, spy) = await makeSUT(txUrl: nil)

        _ = try await sut.submit(.four, feedback: nil)

        #expect(await spy.submitCalls.first?.txUrl == nil)
    }

    @Test("Returns alreadyRated when transaction already rated")
    func returnsAlreadyRatedOnSubmit() async throws {
        let existingRating = 3
        let (sut, spy) = await makeSUT(checkResult: .success(ExistingRating(rating: existingRating, feedback: nil)))

        let result = try await sut.submit(.five, feedback: "New")

        #expect(result == .alreadyRated(existingRating))
        #expect(await spy.submitCalls.isEmpty)
    }

    @Test("Submits without feedback")
    func submitsWithoutFeedback() async throws {
        let (sut, spy) = await makeSUT()

        let result = try await sut.submit(.five, feedback: nil)

        #expect(result == .success)
        #expect(await spy.submitCalls.first?.feedback == nil)
    }

    @Test("Throws when submit fails")
    func throwsOnSubmitFailure() async {
        let (sut, _) = await makeSUT(submitResult: .failure(URLError(.timedOut)))

        await #expect(throws: Error.self) {
            try await sut.submit(.three, feedback: nil)
        }
    }

    @Test("Can submit again after error")
    func canSubmitAfterError() async throws {
        let (sut, spy) = await makeSUT(submitResult: .failure(URLError(.timedOut)))

        // First attempt fails
        await #expect(throws: Error.self) {
            try await sut.submit(.four, feedback: nil)
        }

        // Fix the spy and try again
        await spy.setSubmitResult(.success(()))
        let result = try await sut.submit(.four, feedback: nil)

        #expect(result == .success)
    }

    // MARK: - Feedback Normalization

    @Test("Trims leading and trailing whitespace from feedback")
    func trimsFeedback() async throws {
        let (sut, spy) = await makeSUT()

        _ = try await sut.submit(.four, feedback: "  hello world  ")

        #expect(await spy.submitCalls.first?.feedback == "hello world")
    }

    @Test("Normalizes whitespace-only feedback to nil")
    func normalizesWhitespace() async throws {
        let (sut, spy) = await makeSUT()

        _ = try await sut.submit(.four, feedback: "   \n\t  ")

        #expect(await spy.submitCalls.first?.feedback == nil)
    }

    @Test("Trims newlines from feedback")
    func trimsNewlines() async throws {
        let feedback = "Good service"
        let (sut, spy) = await makeSUT()

        _ = try await sut.submit(.four, feedback: "\n\n\(feedback)\n\n")

        #expect(await spy.submitCalls.first?.feedback == feedback)
    }

    // MARK: - Edge Cases

    @Test("Handles long feedback text")
    func handlesLongFeedback() async throws {
        let feedbackLength = 600
        let longFeedback = String(repeating: "A", count: feedbackLength)
        let (sut, spy) = await makeSUT()

        let result = try await sut.submit(.three, feedback: longFeedback)

        #expect(result == .success)
        #expect(await spy.submitCalls.first?.feedback?.count == feedbackLength)
    }

    @Test("Handles emoji in feedback")
    func handlesEmoji() async throws {
        let feedback = "Great! 🚀💰✨ Best swap 👍"
        let (sut, spy) = await makeSUT()

        let result = try await sut.submit(.five, feedback: feedback)

        #expect(result == .success)
        #expect(await spy.submitCalls.first?.feedback == feedback)
    }

    @Test("Handles special characters in feedback")
    func handlesSpecialChars() async throws {
        let feedback = "<script>alert('xss')</script> & \"quotes\""
        let (sut, spy) = await makeSUT()

        _ = try await sut.submit(.two, feedback: feedback)

        #expect(await spy.submitCalls.first?.feedback == feedback)
    }
}

private extension RatingModelTests {
    // MARK: - Helpers

    func makeSUT(
        checkResult: Result<ExistingRating?, Error> = .success(nil),
        submitResult: Result<Void, Error> = .success(()),
        transactionId externalTxId: String = "tx_test",
        provider providerName: String = "TestProvider",
        userWalletIdHash: String = "test_wallet_hash",
        txUrl: String? = "https://example.com/tx"
    ) async -> (sut: RatingModel, spy: RatingProviderSpy) {
        let spy = RatingProviderSpy()
        await spy.setCheckResult(checkResult)
        await spy.setSubmitResult(submitResult)

        let transaction = RatingModel.Transaction(
            transactionId: externalTxId,
            providerName: providerName,
            txUrl: txUrl
        )

        let sut = RatingModel(
            ratingProvider: spy,
            transaction: transaction,
            userWalletIdHash: userWalletIdHash
        )
        return (sut, trackForMemoryLeaks(spy))
    }
}
