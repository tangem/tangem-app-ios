//
//  WalletConnectDuplicateRequestFilterTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import ReownWalletKit
import TangemTestKit
@testable import Tangem

final class WalletConnectDuplicateRequestFilterTests: LeakTrackingTestSuite {
    @Test
    func shouldAllowRequestProcessingWhenFilterIsEmpty() async throws {
        let sut = makeSUT()
        let request = try Self.makeAnyRequest()

        #expect(await sut.isProcessingAllowed(for: request))
    }

    @Test(
        arguments: [
            (Timings.IntervalBetweenRequests.zero, false),
            (Timings.IntervalBetweenRequests.wayNotEnough, false),
            (Timings.IntervalBetweenRequests.almostEnough, false),
            (Timings.IntervalBetweenRequests.exactlyEnough, true),
            (Timings.IntervalBetweenRequests.barelyEnough, true),
            (Timings.IntervalBetweenRequests.moreThanEnough, true),
        ]
    )
    func shouldAllowDuplicateRequestOnlyAfterEnoughInterval(timeBetweenRequests: TimeInterval, isDuplicateAllowed: Bool) async throws {
        let dateProvider = makeMockDateProvider()
        let sut = makeSUT(currentDateProvider: dateProvider.callAsFunction)

        let request = try Self.makeAnyRequest()
        let duplicateRequest = try Self.makeAnyRequest()

        #expect(await sut.isProcessingAllowed(for: request))
        dateProvider.advance(by: timeBetweenRequests)

        #expect(await sut.isProcessingAllowed(for: duplicateRequest) == isDuplicateAllowed)
    }

    @Test(
        arguments: [
            (Timings.IntervalBetweenRequests.zero, false),
            (Timings.IntervalBetweenRequests.wayNotEnough, false),
            (Timings.IntervalBetweenRequests.almostEnough, false),
            (Timings.IntervalBetweenRequests.exactlyEnough, true),
            (Timings.IntervalBetweenRequests.barelyEnough, true),
            (Timings.IntervalBetweenRequests.moreThanEnough, true),
        ]
    )
    func shouldAllowSequentialDuplicateRequestsOnlyAfterEnoughInterval(timeBetweenRequests: TimeInterval, isDuplicateAllowed: Bool) async throws {
        let dateProvider = makeMockDateProvider()
        let sut = makeSUT(currentDateProvider: dateProvider.callAsFunction)

        let request = try Self.makeAnyRequest()

        #expect(await sut.isProcessingAllowed(for: request))

        for _ in 0 ..< 9 {
            let duplicateRequest = try Self.makeAnyRequest()
            dateProvider.advance(by: timeBetweenRequests)
            #expect(await sut.isProcessingAllowed(for: duplicateRequest) == isDuplicateAllowed)
        }
    }

    @Test(
        arguments: [
            Timings.IntervalBetweenRequests.zero,
            Timings.IntervalBetweenRequests.wayNotEnough,
            Timings.IntervalBetweenRequests.almostEnough,
            Timings.IntervalBetweenRequests.exactlyEnough,
            Timings.IntervalBetweenRequests.barelyEnough,
            Timings.IntervalBetweenRequests.moreThanEnough,
        ]
    )
    func shouldAllowSequentialUniqueRequestsAfterAnyInterval(timeBetweenRequests: TimeInterval) async throws {
        let dateProvider = makeMockDateProvider()
        let sut = makeSUT(currentDateProvider: dateProvider.callAsFunction)

        let request = try Self.makeAnyRequest()

        #expect(await sut.isProcessingAllowed(for: request))

        for i in 0 ..< 9 {
            let uniqueRequest = try Self.makeAnyRequest(topic: "unique-request-#\(i)-topic")
            dateProvider.advance(by: timeBetweenRequests)
            #expect(await sut.isProcessingAllowed(for: uniqueRequest))
        }
    }
}

// MARK: - Factory methods

extension WalletConnectDuplicateRequestFilterTests {
    private func makeSUT(currentDateProvider: @escaping () -> Date = Date.init) -> WalletConnectDuplicateRequestFilter {
        trackForMemoryLeaks(
            WalletConnectDuplicateRequestFilter(
                requiredIntervalBetweenDuplicateRequests: Timings.requiredInterval,
                currentDateProvider: currentDateProvider
            )
        )
    }

    private func makeMockDateProvider() -> MockCurrentDateProvider {
        trackForMemoryLeaks(MockCurrentDateProvider(referenceDate: Timings.referenceDate))
    }

    private static func makeAnyRequest(topic: String = "anyTopic") throws -> ReownWalletKit.Request {
        let anyBlockchain = ReownWalletKit.Blockchain(namespace: "eip155", reference: "1")

        return try ReownWalletKit.Request(
            topic: topic,
            method: "eth_sendTransaction",
            params: AnyCodable(any: ["anyMessage", "anyAddress"]),
            chainId: try #require(anyBlockchain)
        )
    }
}

// MARK: - Nested types

extension WalletConnectDuplicateRequestFilterTests {
    private enum Timings {
        static let referenceDate = Date(timeIntervalSinceReferenceDate: 123456789)
        static let requiredInterval: TimeInterval = 5

        enum IntervalBetweenRequests {
            static let zero = TimeInterval.zero
            static let wayNotEnough: TimeInterval = Timings.requiredInterval.advanced(by: -4.9)
            static let almostEnough: TimeInterval = Timings.requiredInterval.advanced(by: -0.1)
            static let exactlyEnough = Timings.requiredInterval
            static let barelyEnough: TimeInterval = Timings.requiredInterval.advanced(by: 0.1)
            static let moreThanEnough: TimeInterval = Timings.requiredInterval.advanced(by: 100)
        }
    }

    private final class MockCurrentDateProvider {
        private var currentDate: Date

        init(referenceDate: Date) {
            currentDate = referenceDate
        }

        func advance(by interval: TimeInterval) {
            currentDate = currentDate.advanced(by: interval)
        }

        func callAsFunction() -> Date {
            currentDate
        }
    }
}
