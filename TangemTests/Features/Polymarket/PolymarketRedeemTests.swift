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

        let record = try await sut.claim(conditionId: Self.conditionId, isNegRisk: false)

        #expect(record.state == .confirmed)
        #expect(service.submitted.count == 1)
    }

    @Test("A claim still in flight is polled until it lands")
    func pollsUntilItLands() async throws {
        let service = RedeemServiceSpy(submit: .inProgress, records: [.success(.stub(state: .inProgress)), .success(.stub(state: .confirmed))])
        let sut = try makeSUT(redeemService: service)

        let record = try await sut.claim(conditionId: Self.conditionId, isNegRisk: false)

        #expect(record.state == .confirmed)
    }

    @Test("A claim that never settles inside its window is not a success")
    func neverSettledIsNotSuccess() async throws {
        let service = RedeemServiceSpy(submit: .inProgress, records: Array(repeating: .success(.stub(state: .inProgress)), count: 40))
        let sut = try makeSUT(redeemService: service)

        await #expect(throws: PolymarketRedeemTransactionService.Error.self) {
            _ = try await sut.claim(conditionId: Self.conditionId, isNegRisk: false)
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
            _ = try await sut.claim(conditionId: Self.conditionId, isNegRisk: false)
        }
    }

    @Test("A claim the chain rejected is surfaced as a failure")
    func rejectedOnChain() async throws {
        let service = RedeemServiceSpy(submit: .failed, records: [])
        let sut = try makeSUT(redeemService: service)

        await #expect(throws: PolymarketRedeemTransactionService.Error.self) {
            _ = try await sut.claim(conditionId: Self.conditionId, isNegRisk: false)
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

        _ = try await sut.claim(conditionId: Self.conditionId, isNegRisk: false)

        #expect(service.submitted.count == 2)
        #expect(service.submitted[0] == service.submitted[1])
    }

    @Test("A refusal from the relayer is reported, not retried forever")
    func relayerRefusalIsReported() async throws {
        let service = RedeemServiceSpy(submit: .confirmed, records: [], submitFailures: [.relayerRejected(detail: "not redeemable")])
        let sut = try makeSUT(redeemService: service)

        await #expect(throws: PolymarketRedeemTransactionService.Error.self) {
            _ = try await sut.claim(conditionId: Self.conditionId, isNegRisk: false)
        }

        #expect(service.submitted.count == 1)
    }

    @Test("A claim the user refused to sign reads as a cancellation")
    func cancellationStaysACancellation() async throws {
        let sut = try makeSUT(redeemService: RedeemServiceSpy(submit: .confirmed, records: []), signer: CancellingSigner())

        await #expect(throws: CancellationError.self) {
            _ = try await sut.claim(conditionId: Self.conditionId, isNegRisk: false)
        }
    }

    @Test("The batch carries exactly the one call the backend handed out")
    func batchCarriesOneCall() async throws {
        let service = RedeemServiceSpy(submit: .confirmed, records: [])
        let sut = try makeSUT(redeemService: service)

        _ = try await sut.claim(conditionId: Self.conditionId, isNegRisk: true)

        let batch = try #require(service.submitted.first)

        #expect(batch.calls.count == 1)
        #expect(batch.calls[0].value == "0")
        #expect(service.requestedNegRisk == true)
    }

    private func makeSUT(
        redeemService: RedeemServiceSpy,
        signer: PolymarketBatchSigning = PassthroughSigner()
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
            pollDelayProvider: InstantPollDelayProvider()
        )
    }

    static let conditionId = "0x" + String(repeating: "a", count: 64)
}

// MARK: - Doubles

private enum Constants {
    static let adapter = "0xada2005600dec949baf300f4c6120000bdb6eaab"
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
        var requestedNegRisk: Bool?
        var records: [Result<PolymarketRedeemRecord, PolymarketRedeemError>]
        var submitFailures: [PolymarketRedeemError]
    }

    private let submitState: PolymarketRedeemState
    private let state: OSAllocatedUnfairLock<State>

    init(
        submit: PolymarketRedeemState,
        records: [Result<PolymarketRedeemRecord, PolymarketRedeemError>],
        submitFailures: [PolymarketRedeemError] = []
    ) {
        submitState = submit
        state = .init(initialState: State(records: records, submitFailures: submitFailures))
    }

    var submitted: [PolymarketRelayedBatch] {
        state.withLock { $0.submitted }
    }

    var requestedNegRisk: Bool? {
        state.withLock { $0.requestedNegRisk }
    }

    func call(conditionId: String, isNegRisk: Bool) async throws(PolymarketRedeemError) -> PolymarketRelayedBatch.Call {
        state.withLock { $0.requestedNegRisk = isNegRisk }

        return PolymarketRelayedBatch.Call(target: Constants.adapter, data: "0x01b7037c")
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
