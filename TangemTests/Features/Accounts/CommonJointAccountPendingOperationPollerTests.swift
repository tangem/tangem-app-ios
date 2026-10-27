//
//  CommonJointAccountPendingOperationPollerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

// MARK: - Tests

@Suite("Tests for asking the delegate to read one joint account operation anew on a schedule")
struct CommonJointAccountPendingOperationPollerTests {
    @Test("At the regular pace the first read waits out the interval")
    func regularPaceWaitsBeforeTheFirstRead() async throws {
        let updater = JointAccountPendingOperationPollerLoaderStub()
        let sut = Self.makeSUT(updater: updater, intervals: Self.slowRegularIntervals)

        try await Task.sleep(for: .milliseconds(50))

        #expect(updater.reloadedOperations.isEmpty)
        withExtendedLifetime(sut) {}
    }

    @Test("At the regular pace the operation is read again and again")
    func regularPaceKeepsReading() async throws {
        let updater = JointAccountPendingOperationPollerLoaderStub()
        let sut = Self.makeSUT(updater: updater, intervals: Self.fastIntervals)

        try await updater.waitForReloads(reaching: 3)

        #expect(updater.reloadedOperations.allSatisfy { $0.operationId == Self.operationId && $0.cryptoAccountId == Self.accountId })
        withExtendedLifetime(sut) {}
    }

    @Test("Frequent updates are read right away, and let go with the request")
    func frequentUpdatesAreReadWhileAskedFor() async throws {
        let updater = JointAccountPendingOperationPollerLoaderStub()
        let sut = Self.makeSUT(updater: updater, intervals: Self.slowRegularIntervals)

        let frequentUpdates = sut.requestFrequentUpdates()
        try await updater.waitForReloads(reaching: 3)

        frequentUpdates?.cancel()
        try await Task.sleep(for: .milliseconds(200))

        let readsAfterRelease = updater.reloadedOperations.count
        try await Task.sleep(for: .milliseconds(100))

        #expect(updater.reloadedOperations.count == readsAfterRelease)
        withExtendedLifetime(sut) {}
    }

    @Test("Frequent updates go on while any request holds them")
    func frequentUpdatesLastWhileAnyRequestHolds() async throws {
        let updater = JointAccountPendingOperationPollerLoaderStub()
        let sut = Self.makeSUT(updater: updater, intervals: Self.slowRegularIntervals)

        let first = sut.requestFrequentUpdates()
        let second = sut.requestFrequentUpdates()
        first?.cancel()
        try await updater.waitForReloads(reaching: 3)

        second?.cancel()
        withExtendedLifetime(sut) {}
    }

    @Test("The tag of a changed answer goes with the next read, and an unchanged answer keeps it")
    func tagOfAChangedAnswerGoesWithTheNextRead() async throws {
        let updater = JointAccountPendingOperationPollerLoaderStub(answers: [
            .modified(Self.historyItem, eTag: "v1"),
            .notModified,
        ])
        let sut = Self.makeSUT(updater: updater, intervals: Self.fastIntervals)

        try await updater.waitForReloads(reaching: 3)

        #expect(Array(updater.sentKnownETags.prefix(3)) == [nil, "v1", "v1"])
        withExtendedLifetime(sut) {}
    }

    @Test("A failed read is retried on the next run")
    func failedReadIsRetried() async throws {
        let updater = JointAccountPendingOperationPollerLoaderStub(error: "The network is down")
        let sut = Self.makeSUT(updater: updater, intervals: Self.fastIntervals)

        try await updater.waitForReloads(reaching: 3)
        withExtendedLifetime(sut) {}
    }

    @Test("A poller let go reads no more")
    func releasedPollerReadsNoMore() async throws {
        let updater = JointAccountPendingOperationPollerLoaderStub()
        var sut: CommonJointAccountPendingOperationPoller? = Self.makeSUT(updater: updater, intervals: Self.fastIntervals)

        try await updater.waitForReloads(reaching: 1)
        sut = nil
        try await Task.sleep(for: .milliseconds(200))

        let readsAfterRelease = updater.reloadedOperations.count
        try await Task.sleep(for: .milliseconds(100))

        #expect(updater.reloadedOperations.count == readsAfterRelease)
        #expect(sut == nil)
    }
}

// MARK: - Helpers

private extension CommonJointAccountPendingOperationPollerTests {
    static let operationId = "0E2F4A6C-8D0B-4C5E-9F1A-2D4B6C8E0F2A"
    static let accountId = JointAccountCompositionFixture.caseFlippedCryptoAccountId
    static let historyItem = JointOperationHistoryItem(
        operation: JointAccountCompositionFixture.coinTransfer(status: .pending),
        cryptoAccountId: accountId,
        safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b",
        createdAt: Date(timeIntervalSince1970: 1_767_225_600),
        threshold: 2
    )

    static let fastIntervals = CommonJointAccountPendingOperationPoller.Intervals(regular: .milliseconds(10), frequent: .milliseconds(10))
    static let slowRegularIntervals = CommonJointAccountPendingOperationPoller.Intervals(regular: .seconds(10), frequent: .milliseconds(10))

    static func makeSUT(
        updater: JointAccountPendingOperationPollerLoaderStub,
        intervals: CommonJointAccountPendingOperationPoller.Intervals
    ) -> CommonJointAccountPendingOperationPoller {
        CommonJointAccountPendingOperationPoller(cryptoAccountId: accountId, operationId: operationId, delegate: updater, intervals: intervals)
    }
}
