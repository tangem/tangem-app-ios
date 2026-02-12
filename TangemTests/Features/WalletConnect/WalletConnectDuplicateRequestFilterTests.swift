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
@testable import Tangem

struct WalletConnectDuplicateRequestFilterTests {
    @Test
    func shouldAllowRequestProcessingWhenFilterIsEmpty() async throws {
        let sut = Self.makeSUT()
        let request = try Self.makeAnyRequest()

        #expect(await sut.isProcessingAllowed(for: request))
    }

    @Test(
        arguments: [
            (Timings.NotEnoughInterval.zero, false),
            (Timings.NotEnoughInterval.wayNotEnough, false),
            (Timings.NotEnoughInterval.almostEnough, false),
            (Timings.EnoughInterval.barelyEnough, true),
            (Timings.EnoughInterval.moreThanEnough, true),
        ]
    )
    func shouldAllowDuplicateRequestOnlyAfterEnoughInterval(timeBetweenRequests: TimeInterval, isDuplicateAllowed: Bool) async throws {
        let dateProvider = Self.makeMockDateProvider()
        let sut = Self.makeSUT(currentDateProvider: dateProvider.callAsFunction)

        let request = try Self.makeAnyRequest()
        let duplicateRequest = try Self.makeAnyRequest()

        #expect(await sut.isProcessingAllowed(for: request))
        dateProvider.advance(by: timeBetweenRequests)

        #expect(await sut.isProcessingAllowed(for: duplicateRequest) == isDuplicateAllowed)
    }
}

// MARK: - Factory methods

extension WalletConnectDuplicateRequestFilterTests {
    private static func makeSUT(currentDateProvider: @escaping () -> Date = Date.init) -> WalletConnectDuplicateRequestFilter {
        WalletConnectDuplicateRequestFilter(
            window: Timings.requiredWindow,
            currentDateProvider: currentDateProvider
        )
    }

    private static func makeMockDateProvider() -> MockCurrentDateProvider {
        MockCurrentDateProvider(referenceDate: Timings.referenceDate)
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
        static let requiredWindow: TimeInterval = 5

        enum NotEnoughInterval {
            static let zero = TimeInterval.zero
            static let wayNotEnough: TimeInterval = Timings.requiredWindow.advanced(by: -4.9)
            static let almostEnough: TimeInterval = Timings.requiredWindow.advanced(by: -0.1)
        }

        enum EnoughInterval {
            static let barelyEnough: TimeInterval = Timings.requiredWindow.advanced(by: 0.1)
            static let moreThanEnough: TimeInterval = Timings.requiredWindow.advanced(by: 100)
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
