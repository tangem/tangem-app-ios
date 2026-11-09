//
//  PolymarketOrderPlacementServiceTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
import TangemPolymarket
@testable import Tangem

@MainActor
@Suite("Polymarket delayed order settlement", .timeLimit(.minutes(1)))
struct PolymarketOrderPlacementServiceTests {
    @Test("An order the exchange took at once is handed back as it is, without reading it again")
    func immediatePlacementIsReturnedAsIs() async throws {
        let placement = PolymarketOrderPlacement(
            orderId: Self.orderId,
            status: .matched,
            makingAmount: 100,
            takingAmount: 138,
            transactionHashes: ["0xhash"]
        )
        let placer = OrderPlacerStub(placement: placement)

        let result = try await place(with: placer)

        #expect(result == placement)
        #expect(placer.orderReads == 0)
    }

    @Test("A delayed order that later matches is reported with what it filled")
    func delayedOrderSettles() async throws {
        let record = PolymarketOrderRecord(status: .matched, originalSize: 138, matchedSize: 138, price: Decimal(string: "0.72")!)
        let placer = OrderPlacerStub(records: [.success(Self.record(.live)), .success(record)])

        let result = try await place(with: placer)

        #expect(result == .settled(record, orderId: Self.orderId, side: Self.quote.side))
        #expect(result.takingAmount == 138)
        #expect(placer.orderReads == 2)
    }

    @Test(
        "A delayed order the exchange dropped is a rejection, not an unknown outcome",
        arguments: [PolymarketOrderRecordStatus.canceled, .canceledMarketResolved, .invalid]
    )
    func droppedDelayedOrderIsRejected(_ status: PolymarketOrderRecordStatus) async throws {
        let placer = OrderPlacerStub(records: [.success(Self.record(status))])

        let error = try await #require(throws: PolymarketOrderPlacementError.self) {
            try await place(with: placer)
        }

        #expect(error.isRejected)
    }

    @Test("A delayed order that can't be read back has an unknown outcome")
    func unreadableDelayedOrderIsAmbiguous() async throws {
        let placer = OrderPlacerStub(records: [.failure(StubError())])

        let error = try await #require(throws: PolymarketOrderPlacementError.self) {
            try await place(with: placer)
        }

        #expect(error.isAmbiguous)
        #expect(placer.orderReads == 1)
    }

    @Test("A delayed order still open when the wait runs out has an unknown outcome")
    func neverSettledDelayedOrderIsAmbiguous() async throws {
        let placer = OrderPlacerStub(records: [.success(Self.record(.live))])

        let error = try await #require(throws: PolymarketOrderPlacementError.self) {
            try await place(with: placer)
        }

        #expect(error.isAmbiguous)
        #expect(placer.orderReads == 3)
    }

    @Test("Leaving while a delayed order settles cancels the wait instead of reporting a failure")
    func cancellationStaysACancellation() async throws {
        let delays = PolymarketSteppedDelayProvider()
        let placer = OrderPlacerStub(records: [.success(Self.record(.matched))])
        let task = Task {
            try await place(with: placer, delays: delays)
        }

        try await delays.waitUntilParked(Self.pollInterval)
        task.cancel()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(placer.orderReads == 0)
    }
}

// MARK: - Fixtures

private extension PolymarketOrderPlacementServiceTests {
    static let orderId = "order"
    static let pollInterval: TimeInterval = 10
    static let quote = PolymarketOrderQuote.stub(status: .full)

    struct StubError: Error {}

    static func record(_ status: PolymarketOrderRecordStatus) -> PolymarketOrderRecord {
        PolymarketOrderRecord(status: status, originalSize: 138, matchedSize: 0, price: Decimal(string: "0.72")!)
    }

    func place(
        with placer: OrderPlacerStub,
        delays: PollDelayProvider = PolymarketSteppedDelayProvider(passing: { _ in true })
    ) async throws -> PolymarketOrderPlacement {
        let sut = CommonPolymarketOrderPlacementService(
            userWalletId: UserWalletId(value: Data([0x01, 0x02, 0x03])),
            ownerAddressProvider: PolymarketOwnerAddressProviderStub(derived: PolymarketOwnerAddressProviderStub.ownerAddress),
            credentialsRepository: PolymarketCredentialsRepositoryStub(stored: PolymarketCredentialsRepositoryStub.credentials),
            placer: placer,
            delayProvider: delays
        )

        return try await sut.place(quote: Self.quote, market: .fixture, outcome: .fixture)
    }
}

// MARK: - Doubles

private final class OrderPlacerStub: PolymarketOrderPlacing {
    private let placement: PolymarketOrderPlacement
    private let state: OSAllocatedUnfairLock<State>

    init(
        placement: PolymarketOrderPlacement = PolymarketOrderPlacement(
            orderId: "order",
            status: .delayed,
            makingAmount: nil,
            takingAmount: nil,
            transactionHashes: []
        ),
        records: [Result<PolymarketOrderRecord, Error>] = []
    ) {
        self.placement = placement
        state = OSAllocatedUnfairLock(uncheckedState: State(records: records))
    }

    var orderReads: Int {
        state.withLock { $0.orderReads }
    }

    func place(_ options: PolymarketOrderPlacer.Options) async throws -> PolymarketOrderPlacement {
        placement
    }

    func order(id: String, credentials: PolymarketL2Credentials, ownerAddress: String) async throws -> PolymarketOrderRecord {
        try state.withLockUnchecked { state in
            state.orderReads += 1

            let result = state.records.count > 1 ? state.records.removeFirst() : state.records.first

            guard let result else {
                throw PolymarketOrderPlacementServiceTests.StubError()
            }

            return try result.get()
        }
    }

    private struct State {
        var records: [Result<PolymarketOrderRecord, Error>]
        var orderReads = 0
    }
}

private extension PolymarketOrderPlacementError {
    var isRejected: Bool {
        if case .rejected = self { return true }

        return false
    }
}
