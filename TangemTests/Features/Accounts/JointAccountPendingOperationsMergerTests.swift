//
//  JointAccountPendingOperationsMergerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Testing
import TangemFoundation
@testable import Tangem

// MARK: - Tests

@Suite("Tests for merging the updates of a wallet's joint account operations")
struct JointAccountPendingOperationsMergerTests {
    private let sut = JointAccountPendingOperationsMerger(dateProvider: FixedDateProvider(now: Self.now))

    @Test("An operation of an account nothing is stored for gets a record of its own")
    func operationOfANewAccountIsAdded() {
        let merged = sut.merge([], applying: .localOperation(Self.operation("a"), cryptoAccountId: Self.accountId))

        #expect(merged == [Self.record(Self.operation("a"))])
    }

    @Test("An operation already stored is updated in place, so the order the listing reported survives")
    func operationIsUpdatedInPlace() {
        let stored = [Self.record(Self.operation("a"), Self.operation("b"))]

        let merged = sut.merge(stored, applying: .localOperation(Self.operation("a", status: .pending), cryptoAccountId: Self.accountId))

        #expect(merged == [Self.record(Self.operation("a", status: .pending), Self.operation("b"))])
    }

    @Test(
        "A finished answer keeps the operation, stamped with the time it was learnt of when the endpoint named none",
        arguments: [JointAccountOperationStatus.executed, .failed, .cancelled, .unknown]
    )
    func finishedOperationIsKeptAndStamped(status: JointAccountOperationStatus) {
        let stored = [Self.record(Self.operation("a", status: .pending), Self.operation("b"))]

        let merged = sut.merge(stored, applying: .localOperation(Self.operation("a", status: status), cryptoAccountId: Self.accountId))

        #expect(merged == [Self.record(Self.operation("a", status: status, finishedAt: Self.now), Self.operation("b"))])
    }

    @Test("A finished answer that names its time keeps that time")
    func finishedOperationKeepsItsOwnTime() {
        let stored = [Self.record(Self.operation("a", status: .pending))]
        let finished = Self.operation("a", status: .executed, finishedAt: Self.now.addingTimeInterval(-60))

        let merged = sut.merge(stored, applying: .localOperation(finished, cryptoAccountId: Self.accountId))

        #expect(merged == [Self.record(finished)])
    }

    @Test("A stored finished operation is not taken back in flight by a later answer")
    func finishedOperationIsNotDowngraded() {
        let stored = [Self.record(Self.operation("a", status: .executed, finishedAt: Self.now.addingTimeInterval(-60)))]

        let merged = sut.merge(stored, applying: .localOperation(Self.operation("a", status: .pending), cryptoAccountId: Self.accountId))

        #expect(merged == stored)
    }

    @Test("A finished answer over a stored finished operation keeps the time already known")
    func finishedOperationKeepsTheEarlierTime() {
        let earlier = Self.now.addingTimeInterval(-60)
        let stored = [Self.record(Self.operation("a", status: .executed, finishedAt: earlier))]

        let merged = sut.merge(stored, applying: .localOperation(Self.operation("a", status: .executed), cryptoAccountId: Self.accountId))

        #expect(merged == [Self.record(Self.operation("a", status: .executed, finishedAt: earlier))])
    }

    @Test("A finished operation of an account nothing is stored for gets a record of its own as well")
    func finishedOperationOfANewAccountIsAdded() {
        let merged = sut.merge([], applying: .localOperation(Self.operation("a", status: .executed), cryptoAccountId: Self.accountId))

        #expect(merged == [Self.record(Self.operation("a", status: .executed, finishedAt: Self.now))])
    }

    @Test("A removed operation takes the account's record away with it when it was the last one")
    func removedOperationLeavesNoEmptyRecord() {
        let stored = [Self.record(Self.operation("a")), Self.record(Self.operation("b"), cryptoAccountId: Self.otherAccountId)]

        let merged = sut.merge(stored, applying: .operationRemoved(id: "a", cryptoAccountId: Self.accountId))

        #expect(merged == [Self.record(Self.operation("b"), cryptoAccountId: Self.otherAccountId)])
    }

    @Test("Removing an operation of an account nothing is stored for leaves no record")
    func removedOperationOfAnUnknownAccountLeavesNoRecord() {
        let stored = [Self.record(Self.operation("a"))]

        let merged = sut.merge(stored, applying: .operationRemoved(id: "b", cryptoAccountId: Self.otherAccountId))

        #expect(merged == stored)
    }

    @Test("The listing brings only the operations in flight, and an account left with none gets no record")
    func listingBringsOnlyTheOperationsInFlight() {
        let listing = [
            Self.record(Self.operation("a"), Self.operation("b", status: .executed), Self.operation("c", status: .pending)),
            Self.record(Self.operation("d", status: .unknown), cryptoAccountId: Self.otherAccountId),
        ]

        let merged = sut.merge(listing: listing, into: [], replaying: [])

        #expect(merged == [Self.record(Self.operation("a"), Self.operation("c", status: .pending))])
    }

    @Test("The listing only adds what it reports, and every stored operation stays as it is, the ones it no longer reports included")
    func listingOnlyAddsWhatItReports() {
        let finished = Self.operation("a", status: .executed, finishedAt: Self.now.addingTimeInterval(-60))
        let cancelled = Self.operation("e", status: .cancelled, finishedAt: Self.now.addingTimeInterval(-60))
        let stored = [
            Self.record(finished, Self.operation("b")),
            Self.record(cancelled, cryptoAccountId: Self.otherAccountId),
        ]
        let listing = [Self.record(Self.operation("c"))]

        let merged = sut.merge(listing: listing, into: stored, replaying: [])

        #expect(merged == [
            Self.record(finished, Self.operation("b"), Self.operation("c")),
            Self.record(cancelled, cryptoAccountId: Self.otherAccountId),
        ])
    }

    @Test("An operation in flight already stored is not overwritten by what the listing reports of it")
    func listingDoesNotOverwriteAStoredOperationInFlight() {
        let stored = [Self.record(Self.operation("a", status: .pending))]
        let listing = [Self.record(Self.operation("a"))]

        let merged = sut.merge(listing: listing, into: stored, replaying: [])

        #expect(merged == stored)
    }

    @Test("A stored finished operation the listing still reports in flight stays finished")
    func listingDoesNotDowngradeAFinishedOperation() {
        let finished = Self.operation("a", status: .executed, finishedAt: Self.now.addingTimeInterval(-60))
        let stored = [Self.record(finished)]
        let listing = [Self.record(Self.operation("a", status: .pending))]

        let merged = sut.merge(listing: listing, into: stored, replaying: [])

        #expect(merged == stored)
    }

    @Test("A finished operation older than a day is dropped at any write, the rest staying")
    func finishedOperationOlderThanADayIsDropped() {
        let dayOld = Self.operation("a", status: .executed, finishedAt: Self.now.addingTimeInterval(-Self.day))
        let fresh = Self.operation("b", status: .cancelled, finishedAt: Self.now.addingTimeInterval(-Self.day + 1))
        let stored = [Self.record(dayOld, fresh, Self.operation("c"))]

        let afterAnUpdate = sut.merge(stored, applying: .localOperation(Self.operation("c", status: .pending), cryptoAccountId: Self.accountId))
        let afterAListing = sut.merge(listing: [Self.record(Self.operation("c"))], into: stored, replaying: [])

        #expect(afterAnUpdate == [Self.record(fresh, Self.operation("c", status: .pending))])
        #expect(afterAListing == [Self.record(fresh, Self.operation("c"))])
    }

    @Test("The updates the listing has not seen are replayed over it in the order they were made")
    func unseenUpdatesAreReplayedOverTheListing() {
        let listing = [
            Self.record(Self.operation("a"), Self.operation("b")),
            Self.record(Self.operation("c"), cryptoAccountId: Self.otherAccountId),
        ]

        let merged = sut.merge(listing: listing, into: [], replaying: [
            .localOperation(Self.operation("a", status: .pending), cryptoAccountId: Self.accountId),
            .operationRemoved(id: "b", cryptoAccountId: Self.accountId),
            .localOperation(Self.operation("c", status: .cancelled), cryptoAccountId: Self.otherAccountId),
            .localOperation(Self.operation("d"), cryptoAccountId: Self.otherAccountId),
        ])

        #expect(merged == [
            Self.record(Self.operation("a", status: .pending)),
            Self.record(Self.operation("c", status: .cancelled, finishedAt: Self.now), Self.operation("d"), cryptoAccountId: Self.otherAccountId),
        ])
    }

    @Test("An operation read anew updates the stored one")
    func refreshedOperationUpdatesTheStoredOne() {
        let merged = sut.merge(
            [Self.record(Self.operation("a"))],
            applying: .operationRefreshed(Self.operation("a", status: .pending), cryptoAccountId: Self.accountId)
        )

        #expect(merged == [Self.record(Self.operation("a", status: .pending))])
    }

    @Test("An operation in flight read anew after the store dropped it is not brought back")
    func refreshedOperationInFlightIsNotBroughtBack() {
        let merged = sut.merge([], applying: .operationRefreshed(Self.operation("a", status: .pending), cryptoAccountId: Self.accountId))

        #expect(merged.isEmpty)
    }

    @Test("A finished operation read anew after the store dropped it is kept for the day")
    func refreshedFinishedOperationIsKept() {
        let merged = sut.merge([], applying: .operationRefreshed(Self.operation("a", status: .executed), cryptoAccountId: Self.accountId))

        #expect(merged == [Self.record(Self.operation("a", status: .executed, finishedAt: Self.now))])
    }

    @Test("The account is matched however its identifier is spelled")
    func accountIsMatchedIgnoringCase() {
        let stored = [Self.record(Self.operation("a"), cryptoAccountId: Self.accountId.lowercased())]

        let merged = sut.merge(stored, applying: .localOperation(Self.operation("b"), cryptoAccountId: Self.accountId.uppercased()))

        #expect(merged == [Self.record(Self.operation("a"), Self.operation("b"), cryptoAccountId: Self.accountId.lowercased())])
    }
}

// MARK: - Helpers

private extension JointAccountPendingOperationsMergerTests {
    static let accountId = "0F2A4B6C8D0E2F4A61C8A9E7D6053A1B4C7E2F8D9A0B3C5E7F1A2D4B6C8E0F2A"
    static let otherAccountId = "1B4C7E2F8D9A0B3C5E7F1A2D4B6C8E0F2A4B6C8D0E2F4A61C8A9E7D6053A1B4C"
    static let initiator = "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf"
    static let now = Date(timeIntervalSince1970: 1_767_225_600)
    static let day: TimeInterval = 24 * 60 * 60

    static func record(_ operations: JointAccountOperation..., cryptoAccountId: String = accountId) -> StoredJointAccountPendingOperations {
        StoredJointAccountPendingOperations(cryptoAccountId: cryptoAccountId, operations: operations)
    }

    static func operation(
        _ id: String,
        status: JointAccountOperationStatus = .awaitingSignatures,
        finishedAt: Date? = nil
    ) -> JointAccountOperation {
        JointAccountOperation(
            id: id,
            chainId: 1,
            safeTransaction: SafeTransaction(
                to: "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c",
                value: 1_000_000_000_000_000,
                data: Data(),
                operation: 0,
                safeTxGas: 0,
                baseGas: 100_000,
                gasPrice: 1_000_000_000,
                gasToken: SafeGasToken.coinGasTokenRawValue,
                refundReceiver: initiator,
                nonce: 0
            ),
            status: status,
            txHash: nil,
            finishedAt: finishedAt,
            cancelReason: nil,
            initiator: initiator,
            signatures: []
        )
    }
}
