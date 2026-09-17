//
//  RatingProviderCacheDecoratorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("RatingProviderCacheDecorator")
struct RatingProviderCacheDecoratorTests {
    typealias SUT = RatingProviderCacheDecorator

    // MARK: - Check

    @Test("Asks the decoratee once per transaction and answers repeats from memory", arguments: [nil, 4])
    func asksDecorateeOncePerTransaction(rating: Int?) async throws {
        let existing = rating.map { ExistingRating(rating: $0, feedback: nil) }
        let (sut, spy) = await makeSUT(checkResult: .success(existing))

        let first = try await sut.checkExisting(for: Self.transactionId)
        let second = try await sut.checkExisting(for: Self.transactionId)

        #expect(first == existing)
        #expect(second == existing)
        #expect(await spy.checkCalls == [Self.transactionId])
    }

    @Test("Two checks of one transaction cost a single provider call, however they interleave")
    func twoChecksCostOneCall() async throws {
        let provider = RatingProviderBlockingStub()
        let sut = SUT(decoratee: provider)

        async let first = sut.checkExisting(for: Self.transactionId)
        async let second = sut.checkExisting(for: Self.transactionId)

        await provider.waitForCall()
        await provider.release(with: ExistingRating(rating: 4, feedback: nil))

        let (firstResult, secondResult) = try await (first, second)

        #expect(firstResult == ExistingRating(rating: 4, feedback: nil))
        #expect(secondResult == ExistingRating(rating: 4, feedback: nil))
        #expect(await provider.callsCount == 1)
    }

    @Test("A cancelled caller leaves the lookup running, so its answer still lands in the cache")
    func cancelledCallerKeepsLookupAlive() async throws {
        let provider = RatingProviderBlockingStub()
        let sut = SUT(decoratee: provider)

        let caller = Task { try await sut.checkExisting(for: Self.transactionId) }
        await provider.waitForCall()
        caller.cancel()

        await provider.release(with: ExistingRating(rating: 4, feedback: nil))
        _ = try? await caller.value
        let result = try await sut.checkExisting(for: Self.transactionId)

        #expect(result == ExistingRating(rating: 4, feedback: nil))
        #expect(await provider.callsCount == 1)
    }

    @Test("Keeps transactions apart")
    func keepsTransactionsApart() async throws {
        let (sut, spy) = await makeSUT()

        _ = try await sut.checkExisting(for: "tx_1")
        _ = try await sut.checkExisting(for: "tx_2")

        #expect(await spy.checkCalls == ["tx_1", "tx_2"])
    }

    @Test("Does not remember a check that failed")
    func doesNotRememberFailedCheck() async {
        let (sut, spy) = await makeSUT(checkResult: .failure(URLError(.timedOut)))

        _ = try? await sut.checkExisting(for: Self.transactionId)
        _ = try? await sut.checkExisting(for: Self.transactionId)

        #expect(await spy.checkCalls.count == 2)
    }

    // MARK: - Submit

    @Test("Remembers the rating it has just sent")
    func remembersSubmittedRating() async throws {
        let (sut, spy) = await makeSUT()

        try await sut.submit(request: makeRequest(rating: 5, feedback: "Great"))
        let result = try await sut.checkExisting(for: Self.transactionId)

        #expect(result == ExistingRating(rating: 5, feedback: "Great"))
        #expect(await spy.checkCalls.isEmpty)
    }

    @Test("Does not remember a submit that failed")
    func doesNotRememberFailedSubmit() async throws {
        let (sut, spy) = await makeSUT(submitResult: .failure(URLError(.timedOut)))

        _ = try? await sut.submit(request: makeRequest(rating: 5, feedback: nil))
        let result = try await sut.checkExisting(for: Self.transactionId)

        #expect(result == nil)
        #expect(await spy.checkCalls == [Self.transactionId])
    }

    @Test("Forgets a cached answer once a submit fails, so the retry asks the provider again")
    func failedSubmitInvalidatesCachedAnswer() async throws {
        let (sut, spy) = await makeSUT(submitResult: .failure(URLError(.timedOut)))

        _ = try await sut.checkExisting(for: Self.transactionId)
        _ = try? await sut.submit(request: makeRequest(rating: 5, feedback: nil))

        await spy.setCheckResult(.success(ExistingRating(rating: 5, feedback: nil)))
        let result = try await sut.checkExisting(for: Self.transactionId)

        #expect(result == ExistingRating(rating: 5, feedback: nil))
        #expect(await spy.checkCalls.count == 2)
    }

    @Test("Passes the submit through untouched")
    func passesSubmitThrough() async throws {
        let (sut, spy) = await makeSUT()
        let request = makeRequest(rating: 3, feedback: "ok")

        try await sut.submit(request: request)

        #expect(await spy.submitCalls == [request])
    }
}

// MARK: - Private helpers

private extension RatingProviderCacheDecoratorTests {
    static let transactionId = "tx_test"

    func makeSUT(
        checkResult: Result<ExistingRating?, Error> = .success(nil),
        submitResult: Result<Void, Error> = .success(())
    ) async -> (sut: SUT, spy: RatingProviderSpy) {
        let spy = RatingProviderSpy()
        await spy.setCheckResult(checkResult)
        await spy.setSubmitResult(submitResult)

        return (SUT(decoratee: spy), spy)
    }

    func makeRequest(rating: Int, feedback: String?) -> RatingRequest {
        RatingRequest(
            transactionId: Self.transactionId,
            rating: rating,
            feedback: feedback,
            provider: "TestProvider",
            userWalletIdHash: "hash",
            txUrl: nil
        )
    }
}

// MARK: - RatingProviderBlockingStub

private actor RatingProviderBlockingStub: RatingProvider {
    private(set) var callsCount = 0

    private var releasedRating: ExistingRating?
    private var isReleased = false
    private var waiters: [CheckedContinuation<ExistingRating?, Never>] = []
    private var callObservers: [CheckedContinuation<Void, Never>] = []

    func checkExisting(for transactionId: String) async throws -> ExistingRating? {
        callsCount += 1
        callObservers.forEach { $0.resume() }
        callObservers.removeAll()

        guard isReleased else {
            return await withCheckedContinuation { waiters.append($0) }
        }

        return releasedRating
    }

    func submit(request: RatingRequest) async throws {}

    func waitForCall() async {
        guard callsCount == 0 else { return }
        await withCheckedContinuation { callObservers.append($0) }
    }

    func release(with rating: ExistingRating?) {
        isReleased = true
        releasedRating = rating
        waiters.forEach { $0.resume(returning: rating) }
        waiters.removeAll()
    }
}
