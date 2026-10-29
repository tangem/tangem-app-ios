//
//  PolymarketSessionHealthTests.swift
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

@Suite("Polymarket session health", .timeLimit(.minutes(1)))
struct PolymarketSessionHealthTests {
    @Test("A burst of checks against a wallet that is no longer ready reads its status once, resets once and asks for one reconnect")
    func concurrentChecksFoldIntoOneReaction() async throws {
        let fixture = Fixture(status: .success(.deployed), isReadHeld: true)

        let verdicts = try await withThrowingTaskGroup(of: PolymarketSessionVerdict.self) { group in
            for _ in 0 ..< 20 {
                group.addTask { await fixture.sut.verify() }
            }

            try await fixture.walletService.gate.entered.next()
            fixture.walletService.gate.open()

            return try await group.reduce(into: [PolymarketSessionVerdict]()) { $0.append($1) }
        }

        #expect(verdicts.count == 20)
        #expect(verdicts.allSatisfy { $0 == .reconnectRequired })
        #expect(fixture.walletService.calls == 1)
        #expect(fixture.resets == 1)
        #expect(fixture.reconnectRequests == 1)
    }

    @Test("A 401 from the exchange asks for a reconnect at once, even while our backend still calls the wallet ready")
    func exchangeUnauthorizedRequiresAReconnect() async throws {
        let fixture = Fixture(status: .success(.readyToTrade))

        fixture.unauthorizedEvents.yield()
        try await fixture.reconnects.next()

        #expect(fixture.walletService.calls == 0)
        #expect(fixture.accountGoneFlags == [false])
        #expect(fixture.reconnectRequests == 1)
    }

    @Test("Once the exchange has rejected the credentials, later checks answer at once and never reset again")
    func exchangeUnauthorizedIsFinal() async throws {
        let fixture = Fixture(status: .success(.readyToTrade))

        fixture.unauthorizedEvents.yield()
        try await fixture.reconnects.next()

        #expect(await fixture.sut.verify() == .reconnectRequired)
        #expect(await fixture.sut.report(.deployed) == .reconnectRequired)
        #expect(fixture.walletService.calls == 0)
        #expect(fixture.resets == 1)
        #expect(fixture.reconnectRequests == 1)
    }

    @Test("A ready wallet passes the check without touching the stored onboarding")
    func readyWalletPasses() async {
        let fixture = Fixture(status: .success(.readyToTrade))

        #expect(await fixture.sut.verify() == .ready)
        #expect(fixture.resets == 0)
        #expect(fixture.reconnectRequests == 0)
    }

    @Test(
        "Every status short of ready to trade asks for a reconnect",
        arguments: [
            PolymarketDepositWalletStatus.notCreated,
            .deploymentInProgress,
            .deploymentFailed,
            .deployed,
            .approvalsInProgress,
            .approvalsFailed,
        ]
    )
    func notReadyStatusesRequireAReconnect(status: PolymarketDepositWalletStatus) async {
        let fixture = Fixture(status: .success(status))

        #expect(await fixture.sut.verify() == .reconnectRequired)
        #expect(fixture.resets == 1)
        #expect(fixture.reconnectRequests == 1)
    }

    @Test("A 401 from our backend on the status read is not about the wallet, so the session is left alone")
    func unauthorizedStatusReadIsInconclusive() async {
        let fixture = Fixture(status: .failure(.unauthorized))

        #expect(await fixture.sut.verify() == .inconclusive)
        #expect(fixture.resets == 0)
        #expect(fixture.reconnectRequests == 0)
    }

    @Test("A wallet the backend no longer knows asks for a reconnect")
    func missingWalletRequiresAReconnect() async {
        let fixture = Fixture(status: .failure(.other(.http(statusCode: 404, problemDetail: nil))))

        #expect(await fixture.sut.verify() == .reconnectRequired)
        #expect(fixture.resets == 1)
    }

    @Test("A status that cannot be read leaves the session alone and is asked again next time")
    func unreadableStatusIsInconclusive() async {
        let fixture = Fixture(status: .failure(.upstreamUnavailable(detail: nil)))

        #expect(await fixture.sut.verify() == .inconclusive)
        #expect(await fixture.sut.verify() == .inconclusive)
        #expect(fixture.walletService.calls == 2)
        #expect(fixture.resets == 0)
        #expect(fixture.reconnectRequests == 0)
    }

    @Test("An unrecognised status leaves the session alone")
    func unknownStatusIsInconclusive() async {
        let fixture = Fixture(status: .success(.unknown))

        #expect(await fixture.sut.verify() == .inconclusive)
        #expect(fixture.resets == 0)
    }

    @Test("A status another flow has just read is enough, without asking the backend again")
    func reportedStatusConcludesWithoutARead() async {
        let fixture = Fixture(status: .success(.readyToTrade))

        #expect(await fixture.sut.report(.deployed) == .reconnectRequired)
        #expect(fixture.walletService.calls == 0)
        #expect(fixture.resets == 1)
        #expect(fixture.reconnectRequests == 1)
    }

    @Test("A wallet the backend never created resets the account as gone, a deployed one as needing a reconnect")
    func resetTellsWhetherTheAccountIsGone() async {
        let gone = Fixture(status: .success(.notCreated))
        let deployed = Fixture(status: .success(.deployed))

        await gone.sut.verify()
        await deployed.sut.verify()

        #expect(gone.accountGoneFlags == [true])
        #expect(deployed.accountGoneFlags == [false])
    }

    @Test("A not-ready status reported while an unreadable check runs still asks for a reconnect")
    func reportDuringAnInconclusiveCheckConcludes() async throws {
        let fixture = Fixture(status: .failure(.upstreamUnavailable(detail: nil)), isReadHeld: true)

        let running = Task { await fixture.sut.verify() }
        try await fixture.walletService.gate.entered.next()

        let reporting = Task { await fixture.sut.report(.deployed) }
        fixture.walletService.gate.open()

        #expect(await reporting.value == .reconnectRequired)
        #expect(await running.value == .inconclusive)
        #expect(fixture.walletService.calls == 1)
        #expect(fixture.resets == 1)
        #expect(fixture.reconnectRequests == 1)
    }

    @Test("Once a reconnect is required, later checks answer at once and never reset again")
    func reconnectIsFinal() async {
        let fixture = Fixture(status: .success(.deployed))

        await fixture.sut.verify()

        #expect(await fixture.sut.verify() == .reconnectRequired)
        #expect(await fixture.sut.report(.approvalsFailed) == .reconnectRequired)
        #expect(fixture.walletService.calls == 1)
        #expect(fixture.resets == 1)
        #expect(fixture.reconnectRequests == 1)
    }

    @Test("Without a derived owner key the status cannot be asked for, so nothing is reset")
    func missingOwnerKeyIsInconclusive() async {
        let fixture = Fixture(status: .success(.deployed), ownerAddress: nil)

        #expect(await fixture.sut.verify() == .inconclusive)
        #expect(fixture.walletService.calls == 0)
        #expect(fixture.resets == 0)
    }
}

// MARK: - Fixture

private final class Fixture {
    let walletService: PolymarketWalletStatusServiceStub
    let unauthorizedEvents: AsyncStream<Void>.Continuation
    let reconnects = PolymarketTestSignal<Void>()
    let sut: PolymarketSessionHealth

    var resets: Int { resetFlags.withLock { $0.count } }
    var accountGoneFlags: [Bool] { resetFlags.withLock { $0 } }
    var reconnectRequests: Int { reconnects.recorded.count }

    private let resetFlags: OSAllocatedUnfairLock<[Bool]>

    init(
        status: Result<PolymarketDepositWalletStatus, PolymarketWalletError>,
        ownerAddress: String? = PolymarketOwnerAddressProviderStub.ownerAddress,
        isReadHeld: Bool = false
    ) {
        let resetFlags = OSAllocatedUnfairLock(initialState: [Bool]())
        let (events, continuation) = AsyncStream<Void>.makeStream()

        unauthorizedEvents = continuation

        self.resetFlags = resetFlags
        walletService = PolymarketWalletStatusServiceStub(result: status, gate: PolymarketTestGate(isOpen: !isReadHeld))
        sut = PolymarketSessionHealth(
            walletService: walletService,
            ownerAddressProvider: PolymarketOwnerAddressProviderStub(derived: ownerAddress),
            unauthorizedEvents: events,
            resetOnboarding: { isAccountGone in resetFlags.withLock { $0.append(isAccountGone) } }
        )

        sut.setReconnectHandler { [reconnects] in reconnects.send() }
    }
}

final class PolymarketWalletStatusServiceStub: PolymarketDepositWalletService {
    let gate: PolymarketTestGate

    var calls: Int { gate.entered.recorded.count }

    private let result: Result<PolymarketDepositWalletStatus, PolymarketWalletError>

    init(result: Result<PolymarketDepositWalletStatus, PolymarketWalletError>, gate: PolymarketTestGate = PolymarketTestGate(isOpen: true)) {
        self.result = result
        self.gate = gate
    }

    func depositWalletState(ownerAddress: String?) async throws(PolymarketWalletError) -> PolymarketDepositWallet {
        await gate.pass()

        let status = try result.get()

        return PolymarketDepositWallet(address: PolymarketDepositWalletServiceStub.depositWalletAddress, status: status)
    }

    func deployWallet(
        ownerAddress: String,
        depositWalletAddress: String
    ) async throws(PolymarketWalletError) -> PolymarketDepositWalletStatus {
        try result.get()
    }

    func submitApprovals(_ batch: PolymarketRelayedBatch) async throws(PolymarketWalletError) -> PolymarketDepositWalletStatus {
        try result.get()
    }
}

final class PolymarketSessionHealthSpy: PolymarketSessionHealthChecking {
    var reportedStatuses: [PolymarketDepositWalletStatus] { reported.withLock { $0 } }
    var verifyCalls: Int { verified.withLock { $0 } }

    private let verdict: PolymarketSessionVerdict
    private let reported = OSAllocatedUnfairLock(initialState: [PolymarketDepositWalletStatus]())
    private let verified = OSAllocatedUnfairLock(initialState: 0)

    init(verdict: PolymarketSessionVerdict) {
        self.verdict = verdict
    }

    func verify() async -> PolymarketSessionVerdict {
        verified.withLock { $0 += 1 }
        return verdict
    }

    func report(_ status: PolymarketDepositWalletStatus) async -> PolymarketSessionVerdict {
        reported.withLock { $0.append(status) }
        return verdict
    }
}
