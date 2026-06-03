//
//  RatingViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemTestKit
@testable import Tangem

@Suite("RatingViewModel")
@MainActor
final class RatingViewModelTests: LeakTrackingTestSuite {
    typealias Rating = RatingModel.Rating

    // MARK: - Load

    @Test("Loads and shows unrated state")
    func loadsUnrated() async {
        let spy = RatingProviderSpy()
        await spy.setCheckResult(.success(nil))

        let sut = makeSUT(spy: spy)

        await sut.load()

        #expect(sut.state == .unrated)
    }

    @Test("Loads and shows rated state with rating value")
    func loadsRated() async {
        let spy = RatingProviderSpy()
        await spy.setCheckResult(.success(ExistingRating(rating: 4, feedback: "Good")))

        let sut = makeSUT(spy: spy)

        await sut.load()

        #expect(sut.state == .rated(4))
    }

    @Test("Fail-open: shows unrated state when load fails")
    func loadErrorFailOpen() async {
        let spy = RatingProviderSpy()
        await spy.setCheckResult(.failure(URLError(.notConnectedToInternet)))

        let sut = makeSUT(spy: spy)

        await sut.load()

        // Fail-open: treat errors as "not rated"
        #expect(sut.state == .unrated)
        #expect(sut.isVisible == true)
    }

    @Test("Only loads once (idempotent)")
    func loadsOnce() async {
        let spy = RatingProviderSpy()
        await spy.setCheckResult(.success(nil))

        let sut = makeSUT(spy: spy)

        await sut.load()
        await sut.load()
        await sut.load()

        #expect(await spy.checkCalls.count == 1)
    }

    @Test("State transitions: loading -> unrated")
    func stateTransitionsUnrated() async {
        let spy = RatingProviderSpy()
        await spy.setCheckResult(.success(nil))

        let sut = makeSUT(spy: spy)
        var states: [RatingViewModel.State] = []

        let subscriptionReady = AsyncStream<Void>.makeStream()
        let task = Task {
            var iterator = await sut.$state.values.makeAsyncIterator()
            subscriptionReady.continuation.yield()
            while let state = await iterator.next() {
                states.append(state)
                if state == .unrated { break }
            }
        }

        // Wait for subscription to start
        for await _ in subscriptionReady.stream {
            break
        }

        await sut.load()
        await task.value

        #expect(states.contains(.loading))
        #expect(states.contains(.unrated))
    }

    // MARK: - Submit

    @Test("Submits and shows submitted state")
    func submitsSuccessfully() async throws {
        let spy = RatingProviderSpy()
        await spy.setCheckResult(.success(nil))
        await spy.setSubmitResult(.success(()))

        let sut = makeSUT(spy: spy)

        await sut.load()
        try await sut.submitThrowing(rating: .four, feedback: "Great!")

        #expect(sut.state == .submitted(4))
        let submitCalls = await spy.submitCalls
        #expect(submitCalls.count == 1)
        #expect(submitCalls.first?.rating == 4)
        #expect(submitCalls.first?.feedback == "Great!")
    }

    @Test("Shows rated state if already rated during submit (race condition)")
    func alreadyRatedDuringSubmit() async throws {
        let spy = RatingProviderSpy()
        await spy.setCheckResult(.success(nil))
        await spy.setSubmitResult(.success(()))

        let sut = makeSUT(spy: spy)

        await sut.load()

        // Simulate race: someone rated while we were about to submit
        await spy.setCheckResult(.success(ExistingRating(rating: 3, feedback: nil)))

        try await sut.submitThrowing(rating: .five, feedback: nil)

        #expect(sut.state == .rated(3))
    }

    @Test("Throws error on submit failure")
    func submitThrowsError() async {
        let spy = RatingProviderSpy()
        await spy.setCheckResult(.success(nil))
        await spy.setSubmitResult(.failure(URLError(.timedOut)))

        let sut = makeSUT(spy: spy)

        await sut.load()

        await #expect(throws: (any Error).self) {
            try await sut.submitThrowing(rating: .four, feedback: nil)
        }
    }

    @Test("Resets to unrated on submit failure for retry")
    func resetsToUnratedOnFailure() async {
        let spy = RatingProviderSpy()
        await spy.setCheckResult(.success(nil))
        await spy.setSubmitResult(.failure(URLError(.timedOut)))

        let sut = makeSUT(spy: spy)

        await sut.load()

        do {
            try await sut.submitThrowing(rating: .four, feedback: nil)
        } catch {
            // Expected
        }

        #expect(sut.state == .unrated)
    }

    @Test("Allows retry after failure")
    func allowsRetryAfterFailure() async throws {
        let spy = RatingProviderSpy()
        await spy.setCheckResult(.success(nil))
        await spy.setSubmitResult(.failure(URLError(.timedOut)))

        let sut = makeSUT(spy: spy)

        await sut.load()

        // First attempt fails
        do {
            try await sut.submitThrowing(rating: .four, feedback: nil)
        } catch {
            // Expected
        }

        #expect(sut.state == .unrated)

        // Fix the API
        await spy.setSubmitResult(.success(()))

        // Retry should work
        try await sut.submitThrowing(rating: .four, feedback: "Retry worked!")

        #expect(sut.state == .submitted(4))
        #expect(await spy.submitCalls.count == 2)
    }

    @Test("Does not submit when in rated state")
    func doesNotSubmitWhenRated() async throws {
        let spy = RatingProviderSpy()
        await spy.setCheckResult(.success(ExistingRating(rating: 3, feedback: nil)))

        let sut = makeSUT(spy: spy)

        await sut.load()
        try await sut.submitThrowing(rating: .five, feedback: nil)

        #expect(await spy.submitCalls.isEmpty)
        #expect(sut.state == .rated(3))
    }

    @Test("Does not submit when in loading state")
    func doesNotSubmitWhenLoading() async throws {
        let spy = RatingProviderSpy()

        let sut = makeSUT(spy: spy)

        // Don't call load(), stay in loading
        try await sut.submitThrowing(rating: .five, feedback: nil)

        #expect(await spy.submitCalls.isEmpty)
        #expect(sut.state == .loading)
    }

    @Test("Does not submit when in submitted state")
    func doesNotSubmitWhenSubmitted() async throws {
        let spy = RatingProviderSpy()
        await spy.setCheckResult(.success(nil))
        await spy.setSubmitResult(.success(()))

        let sut = makeSUT(spy: spy)

        await sut.load()
        try await sut.submitThrowing(rating: .four, feedback: nil)
        #expect(sut.state == .submitted(4))

        // Try to submit again
        try await sut.submitThrowing(rating: .five, feedback: "Another")

        #expect(await spy.submitCalls.count == 1) // Only the first submit
    }

    @Test("Submits without feedback")
    func submitsWithoutFeedback() async throws {
        let spy = RatingProviderSpy()
        await spy.setCheckResult(.success(nil))
        await spy.setSubmitResult(.success(()))

        let sut = makeSUT(spy: spy)

        await sut.load()
        try await sut.submitThrowing(rating: .five, feedback: nil)

        #expect(sut.state == .submitted(5))
        #expect(await spy.submitCalls.first?.feedback == nil)
    }

    // MARK: - State Transitions

    @Test("State transitions: unrated -> submitting -> submitted")
    func stateTransitionsSubmit() async throws {
        let spy = RatingProviderSpy()
        await spy.setCheckResult(.success(nil))
        await spy.setSubmitResult(.success(()))

        let sut = makeSUT(spy: spy)

        await sut.load()

        var states: [RatingViewModel.State] = []
        let subscriptionReady = AsyncStream<Void>.makeStream()
        let task = Task {
            var iterator = await sut.$state.values.makeAsyncIterator()
            subscriptionReady.continuation.yield()
            while let state = await iterator.next() {
                states.append(state)
                if case .submitted = state { break }
            }
        }

        // Wait for subscription to start
        for await _ in subscriptionReady.stream {
            break
        }

        try await sut.submitThrowing(rating: .five, feedback: nil)
        await task.value

        #expect(states.contains(.submitting))
        #expect(states.contains(where: { if case .submitted = $0 { true } else { false } }))
    }

    // MARK: - Integration with Model

    @Test("Trims feedback whitespace before sending")
    func trimsFeedback() async throws {
        let spy = RatingProviderSpy()
        await spy.setCheckResult(.success(nil))
        await spy.setSubmitResult(.success(()))

        let sut = makeSUT(spy: spy)

        await sut.load()
        try await sut.submitThrowing(rating: .four, feedback: "  hello world  ")

        #expect(await spy.submitCalls.first?.feedback == "hello world")
    }

    @Test("Normalizes whitespace-only feedback to nil")
    func normalizesWhitespaceFeedback() async throws {
        let spy = RatingProviderSpy()
        await spy.setCheckResult(.success(nil))
        await spy.setSubmitResult(.success(()))

        let sut = makeSUT(spy: spy)

        await sut.load()
        try await sut.submitThrowing(rating: .four, feedback: "   \n\t  ")

        #expect(await spy.submitCalls.first?.feedback == nil)
    }

    // MARK: - isVisible

    @Test("isVisible returns false for loading")
    func isVisibleLoading() {
        let spy = RatingProviderSpy()
        let sut = makeSUT(spy: spy)

        #expect(sut.isVisible == false)
    }

    @Test("isVisible returns true for unrated")
    func isVisibleUnrated() async {
        let spy = RatingProviderSpy()
        await spy.setCheckResult(.success(nil))

        let sut = makeSUT(spy: spy)
        await sut.load()

        #expect(sut.isVisible == true)
    }

    @Test("isVisible returns true for rated")
    func isVisibleRated() async {
        let spy = RatingProviderSpy()
        await spy.setCheckResult(.success(ExistingRating(rating: 4, feedback: nil)))

        let sut = makeSUT(spy: spy)
        await sut.load()

        #expect(sut.isVisible == true)
    }

    @Test("isVisible returns true for submitted")
    func isVisibleSubmitted() async throws {
        let spy = RatingProviderSpy()
        await spy.setCheckResult(.success(nil))
        await spy.setSubmitResult(.success(()))

        let sut = makeSUT(spy: spy)
        await sut.load()
        try await sut.submitThrowing(rating: .five, feedback: nil)

        #expect(sut.isVisible == true)
    }
}

private extension RatingViewModelTests {
    // MARK: - Helpers

    func makeSUT(
        spy: RatingProviderSpy,
        externalTxId: String = "tx_test",
        providerName: String = "TestProvider",
        userWalletIdHash: String = "test_wallet_hash",
        txUrl: String? = "https://example.com/tx"
    ) -> RatingViewModel {
        let transaction = RatingModel.Transaction(
            externalTxId: externalTxId,
            providerName: providerName,
            txUrl: txUrl
        )

        let model = RatingModel(
            ratingProvider: spy,
            transaction: transaction,
            userWalletIdHash: userWalletIdHash
        )

        let viewModel = RatingViewModel(model: model)
        return trackForMemoryLeaks(viewModel)
    }
}
