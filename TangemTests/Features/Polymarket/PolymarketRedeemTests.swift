//
//  PolymarketRedeemTests.swift
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

// MARK: - Claiming end to end

@Suite("Polymarket claim")
struct PolymarketRedeemTransactionServiceTests {
    @Test("A claim that lands on the first read is reported as confirmed")
    func confirmedOnTheFirstRead() async throws {
        let service = RedeemServiceSpy(submit: .confirmed, records: [])
        let sut = try makeSUT(redeemService: service)

        let record = try await sut.claim(position: Self.position())

        #expect(record.state == .confirmed)
        #expect(service.submitted.count == 1)
    }

    @Test("A claim still in flight is polled until it lands")
    func pollsUntilItLands() async throws {
        let service = RedeemServiceSpy(submit: .inProgress, records: [.success(.stub(state: .inProgress)), .success(.stub(state: .confirmed))])
        let sut = try makeSUT(redeemService: service)

        let record = try await sut.claim(position: Self.position())

        #expect(record.state == .confirmed)
    }

    @Test("A claim that never settles inside its window is not a success")
    func neverSettledIsNotSuccess() async throws {
        let service = RedeemServiceSpy(submit: .inProgress, records: Array(repeating: .success(.stub(state: .inProgress)), count: 40))
        let sut = try makeSUT(redeemService: service)

        await #expect(throws: PolymarketRedeemTransactionService.Error.self) {
            _ = try await sut.claim(position: Self.position())
        }
    }

    @Test("Polling that only ever fails is not a success")
    func failedPollingIsNotSuccess() async throws {
        let failures: [Result<PolymarketRedeemRecord, PolymarketRedeemError>] = Array(
            repeating: .failure(.upstreamUnavailable(detail: nil)),
            count: 40
        )
        let service = RedeemServiceSpy(submit: .inProgress, records: failures)
        let sut = try makeSUT(redeemService: service)

        await #expect(throws: PolymarketRedeemTransactionService.Error.self) {
            _ = try await sut.claim(position: Self.position())
        }
    }

    @Test("A claim the chain rejected is surfaced as a failure")
    func rejectedOnChain() async throws {
        let service = RedeemServiceSpy(submit: .failed, records: [])
        let sut = try makeSUT(redeemService: service)

        await #expect(throws: PolymarketRedeemTransactionService.Error.self) {
            _ = try await sut.claim(position: Self.position())
        }
    }

    @Test("A submission that got no answer is resent once")
    func resendsOnceWhenTheAnswerIsLost() async throws {
        let service = RedeemServiceSpy(
            submit: .confirmed,
            records: [],
            submitFailures: [.other(.connection(underlying: StubError()))]
        )
        let sut = try makeSUT(redeemService: service)

        _ = try await sut.claim(position: Self.position())

        #expect(service.submitted.count == 2)
        #expect(service.submitted[0] == service.submitted[1])
    }

    @Test("A refusal from the relayer is reported, not retried forever")
    func relayerRefusalIsReported() async throws {
        let service = RedeemServiceSpy(submit: .confirmed, records: [], submitFailures: [.relayerRejected(detail: "not redeemable")])
        let sut = try makeSUT(redeemService: service)

        await #expect(throws: PolymarketRedeemTransactionService.Error.self) {
            _ = try await sut.claim(position: Self.position())
        }

        #expect(service.submitted.count == 1)
    }

    @Test("A claim the user refused to sign reads as a cancellation")
    func cancellationStaysACancellation() async throws {
        let sut = try makeSUT(redeemService: RedeemServiceSpy(submit: .confirmed, records: []), signer: CancellingSigner())

        await #expect(throws: CancellationError.self) {
            _ = try await sut.claim(position: Self.position())
        }
    }

    @Test("The batch carries exactly the one call the backend handed out")
    func batchCarriesOneCall() async throws {
        let service = RedeemServiceSpy(submit: .confirmed, records: [])
        let sut = try makeSUT(redeemService: service)

        _ = try await sut.claim(position: Self.position(isNegRisk: true))

        let batch = try #require(service.submitted.first)

        #expect(batch.calls.count == 1)
        #expect(batch.calls[0].value == "0")
        #expect(service.request?.isNegRisk == true)
        #expect(service.request?.conditionId == Self.conditionId)
    }

    @Test("Every call the backend handed out goes into one batch, untouched and in order")
    func batchCarriesEveryCallInOrder() async throws {
        let calls = [
            PolymarketRelayedBatch.Call(target: Constants.router, data: "0xd217a3cc01"),
            PolymarketRelayedBatch.Call(target: Constants.router, data: "0xd217a3cc00"),
        ]
        let service = RedeemServiceSpy(submit: .confirmed, records: [], calls: calls)
        let sut = try makeSUT(redeemService: service)

        _ = try await sut.claim(position: Self.position(version: .v2))

        let batch = try #require(service.submitted.first)

        #expect(batch.calls == calls)
        #expect(service.request?.version == .v2)
        #expect(service.request?.assetId == "7")
    }

    @Test("Nothing left to redeem is its own outcome, not a refusal")
    func nothingToRedeemIsReported() async throws {
        let service = RedeemServiceSpy(submit: .confirmed, records: [], callFailure: .nothingToRedeem)
        let sut = try makeSUT(redeemService: service)

        do {
            _ = try await sut.claim(position: Self.position(version: .v2))
            Issue.record("Expected the claim to stop before signing")
        } catch PolymarketRedeemTransactionService.Error.nothingToRedeem {
        } catch {
            Issue.record("Expected nothing to redeem, got \(error)")
        }

        #expect(service.submitted.isEmpty)
    }

    @Test("The deadline is measured by the backend's clock, not by a device running half an hour behind")
    func deadlineFollowsTheBackendClock() async throws {
        let skew: TimeInterval = 1800
        let serverClock = PolymarketServerClock()
        serverClock.record(serverDate: Date().addingTimeInterval(skew))

        let service = RedeemServiceSpy(submit: .confirmed, records: [])
        let sut = try makeSUT(redeemService: service, serverClock: serverClock)

        let before = Date().timeIntervalSince1970
        _ = try await sut.claim(position: Self.position())

        let batch = try #require(service.submitted.first)
        let deadline = try #require(TimeInterval(batch.deadline))

        #expect(abs(deadline - (before + skew + 600)) <= 10)
    }

    private func makeSUT(
        redeemService: RedeemServiceSpy,
        signer: PolymarketBatchSigning = PassthroughSigner(),
        serverClock: PolymarketServerClock = PolymarketServerClock()
    ) throws -> PolymarketRedeemTransactionService {
        let ownerAddress = PolymarketOwnerAddressProviderStub.ownerAddress
        let depositWalletAddress = try PolymarketDepositWalletDeriver.derive(ownerAddress: ownerAddress)

        return PolymarketRedeemTransactionService(
            redeemService: redeemService,
            relayerService: PolymarketRelayerServiceStub(),
            depositWalletResolver: PolymarketDepositWalletResolver(
                walletService: PolymarketDepositWalletServiceStub(
                    status: .readyToTrade,
                    depositWalletAddress: depositWalletAddress
                ),
                ownerAddressProvider: PolymarketOwnerAddressProviderStub(derived: ownerAddress)
            ),
            signer: signer,
            serverClock: serverClock,
            pollDelayProvider: InstantPollDelayProvider()
        )
    }

    static let conditionId = "0x" + String(repeating: "a", count: 64)

    static func position(isNegRisk: Bool = false, version: PolymarketMarketVersion? = .v1) -> PolymarketPosition {
        PolymarketPosition(
            conditionId: conditionId,
            assetId: "7",
            marketId: "3",
            version: version,
            eventId: "4",
            eventTitle: "Event",
            title: "Question",
            iconURL: nil,
            endDate: nil,
            outcome: "Yes",
            outcomeIndex: 0,
            size: 1,
            avgPrice: 1,
            curPrice: 1,
            initialValue: 1,
            currentValue: 1,
            cashPnl: 0,
            pnlRatio: 0,
            realizedPnl: 0,
            isRedeemable: true,
            isNegRisk: isNegRisk,
            isAcceptingOrders: false,
            isLive: false,
            resolutionStatus: .resolved,
            settlement: .won
        )
    }
}

// MARK: - Doubles

private enum Constants {
    static let adapter = "0xada2005600dec949baf300f4c6120000bdb6eaab"
    static let router = "0x12121212006e4cd160d18e3f00711da5c3372600"
}

private struct StubError: Error {}

private struct PassthroughSigner: PolymarketBatchSigning {
    func sign(
        _ batch: PolymarketRelayedBatch.Unsigned,
        as ownerAddress: String
    ) async throws(PolymarketSigningError) -> PolymarketRelayedBatch {
        batch.signed(by: ownerAddress, signature: "0xsignature")
    }
}

private struct CancellingSigner: PolymarketBatchSigning {
    func sign(
        _ batch: PolymarketRelayedBatch.Unsigned,
        as ownerAddress: String
    ) async throws(PolymarketSigningError) -> PolymarketRelayedBatch {
        throw .cancelled
    }
}

private final class RedeemServiceSpy: PolymarketRedeemService {
    private struct State {
        var submitted: [PolymarketRelayedBatch] = []
        var request: PolymarketRedeemCallRequest?
        var records: [Result<PolymarketRedeemRecord, PolymarketRedeemError>]
        var submitFailures: [PolymarketRedeemError]
    }

    private let submitState: PolymarketRedeemState
    private let calls: [PolymarketRelayedBatch.Call]
    private let callFailure: PolymarketRedeemError?
    private let state: OSAllocatedUnfairLock<State>

    init(
        submit: PolymarketRedeemState,
        records: [Result<PolymarketRedeemRecord, PolymarketRedeemError>],
        submitFailures: [PolymarketRedeemError] = [],
        calls: [PolymarketRelayedBatch.Call] = [PolymarketRelayedBatch.Call(target: Constants.adapter, data: "0x01b7037c")],
        callFailure: PolymarketRedeemError? = nil
    ) {
        submitState = submit
        self.calls = calls
        self.callFailure = callFailure
        state = .init(initialState: State(records: records, submitFailures: submitFailures))
    }

    var submitted: [PolymarketRelayedBatch] {
        state.withLock { $0.submitted }
    }

    var request: PolymarketRedeemCallRequest? {
        state.withLock { $0.request }
    }

    func calls(for request: PolymarketRedeemCallRequest) async throws(PolymarketRedeemError) -> [PolymarketRelayedBatch.Call] {
        state.withLock { $0.request = request }

        if let callFailure {
            throw callFailure
        }

        return calls
    }

    func submit(_ batch: PolymarketRelayedBatch) async throws(PolymarketRedeemError) -> PolymarketRedeemRecord {
        let failure = state.withLock { state -> PolymarketRedeemError? in
            state.submitted.append(batch)

            return state.submitFailures.isEmpty ? nil : state.submitFailures.removeFirst()
        }

        if let failure {
            throw failure
        }

        return .stub(state: submitState)
    }

    func record(ofClaim transactionId: String) async throws(PolymarketRedeemError) -> PolymarketRedeemRecord {
        let next = state.withLock { state in
            state.records.isEmpty ? nil : state.records.removeFirst()
        }

        guard let next else {
            return .stub(state: .inProgress)
        }

        return try next.get()
    }
}

// MARK: - Fixtures

private extension PolymarketRedeemRecord {
    static func stub(state: PolymarketRedeemState) -> PolymarketRedeemRecord {
        PolymarketRedeemRecord(
            transactionId: "0x4f2c",
            state: state,
            transactionHash: state == .confirmed ? "0x7ae1" : nil
        )
    }
}
