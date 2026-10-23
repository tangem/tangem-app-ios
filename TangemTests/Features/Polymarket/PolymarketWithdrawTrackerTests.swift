//
//  PolymarketWithdrawTrackerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import TangemFoundation
import TangemPolymarket
@testable import Tangem

@Suite("Polymarket withdraw tracker")
struct PolymarketWithdrawTrackerTests {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)
    private let deadlineOffset: TimeInterval = 600
    private let settlementGrace: TimeInterval = 180
    private let outcomeNoticeLifetime: TimeInterval = 90

    // MARK: - Following a submission

    @Test("An accepted withdrawal is shown as in progress and polled until it confirms")
    func pollsAnAcceptedWithdrawalToConfirmation() async throws {
        let env = makeEnv(recordAnswers: [.success(inProgress()), .success(confirmed())])

        await env.sut.track(inProgress(), deadline: deadline())
        try await env.state(becomes: .confirmed)

        #expect(env.states.contains(.inProgress))
        #expect(env.store.entry() == .init(record: confirmed(), deadline: deadline(), settledAt: now))
        #expect(env.service.recordRequests == 2)

        try await drain()

        #expect(env.service.recordRequests == 2)
    }

    @Test("A withdrawal that fails while polled is shown as failed and kept with the moment it failed")
    func reportsAFailureLearnedWhilePolling() async throws {
        let env = makeEnv(recordAnswers: [.success(failed())])

        await env.sut.track(inProgress(), deadline: deadline())
        try await env.state(becomes: .failed)

        #expect(env.store.entry() == .init(record: failed(), deadline: deadline(), settledAt: now))
    }

    @Test("A withdrawal the backend refuses to report on is dropped without a word")
    func dropsAWithdrawalTheBackendRefuses() async throws {
        let env = makeEnv(recordAnswers: [.failure(.notFound)])

        await env.sut.track(inProgress(), deadline: deadline())
        try await env.state(becomes: nil, after: .inProgress)
        try await drain()

        #expect(env.store.entry() == nil)
        #expect(env.service.recordRequests == 1)
    }

    @Test("A client error the mapping does not name, such as a rate limit, is not a verdict on the withdrawal")
    func retriesAClientErrorTheMappingDoesNotName() async throws {
        let env = makeEnv(recordAnswers: [.failure(.other(.http(statusCode: 429, problemDetail: nil))), .success(confirmed())])

        await env.sut.track(inProgress(), deadline: deadline())
        try await env.state(becomes: .confirmed)

        #expect(env.service.recordRequests == 2)
        #expect(env.store.entry()?.record.state == .confirmed)
    }

    @Test("A backend that is down or unreachable is asked again on the next tick")
    func retriesTransientFailures() async throws {
        let env = makeEnv(recordAnswers: [
            .failure(.upstreamUnavailable(detail: nil)),
            .failure(.other(.http(statusCode: 503, problemDetail: nil))),
            .failure(.other(.connection(underlying: URLError(.notConnectedToInternet)))),
            .success(confirmed()),
        ])

        await env.sut.track(inProgress(), deadline: deadline())
        try await env.state(becomes: .confirmed)

        #expect(env.service.recordRequests == 4)
    }

    @Test("A withdrawal confirmed on submission is never polled")
    func doesNotPollASettledSubmission() async throws {
        let env = makeEnv()

        await env.sut.track(confirmed(), deadline: deadline())
        try await env.state(becomes: .confirmed)
        try await drain()

        #expect(env.service.recordRequests == 0)
        #expect(env.store.entry()?.settledAt == now)
    }

    // MARK: - Resuming after a relaunch

    @Test("A stored withdrawal still in flight is shown and polled again")
    func resumesAStoredWithdrawal() async throws {
        let env = makeEnv(recordAnswers: [.success(confirmed())])
        env.store.save(.init(record: inProgress(), deadline: deadline(), settledAt: nil))

        await env.sut.resume()
        try await env.state(becomes: .confirmed)

        #expect(env.states == [nil, .inProgress, .confirmed])
    }

    @Test("A stored outcome younger than its notice window is shown again")
    func resumesARecentOutcome() async throws {
        let env = makeEnv()
        env.store.save(.init(record: confirmed(), deadline: deadline(), settledAt: now.addingTimeInterval(-30)))

        await env.sut.resume()
        try await env.state(becomes: .confirmed)

        try await settle { env.delays.heldWaits == [outcomeNoticeLifetime - 30] }

        #expect(env.store.entry() != nil)
    }

    @Test("A stored outcome older than its notice window is forgotten without being shown")
    func forgetsAStaleOutcomeOnResume() async throws {
        let env = makeEnv()
        env.store.save(.init(record: failed(), deadline: deadline(), settledAt: now.addingTimeInterval(-outcomeNoticeLifetime - 1)))

        await env.sut.resume()
        try await drain()

        #expect(env.states == [nil, nil])
        #expect(env.store.entry() == nil)
    }

    @Test("Without a stored withdrawal a resume changes nothing")
    func resumesNothingWhenNothingIsStored() async throws {
        let env = makeEnv()

        await env.sut.resume()
        try await drain()

        #expect(env.states == [nil])
        #expect(env.service.recordRequests == 0)
    }

    @Test("A device clock running ahead cannot write off a resumed withdrawal before the backend has answered once")
    func letsTheFirstAnswerCorrectTheClockOnResume() async throws {
        let env = makeEnv(recordAnswers: [.success(confirmed())])
        env.store.save(.init(record: inProgress(), deadline: deadline(), settledAt: nil))
        env.clock.now = now.addingTimeInterval(3600)
        env.service.onRecordRequest = { _ in env.serverClock.record(serverDate: now) }

        await env.sut.resume()
        try await env.state(becomes: .confirmed)
        try await settle { Set(env.delays.heldWaits) == [settlementGrace, outcomeNoticeLifetime] }

        #expect(env.states == [nil, .inProgress, .confirmed])
        #expect(env.store.entry()?.record.state == .confirmed)
    }

    @Test("A withdrawal resumed past its time is forgotten on the first answer that does not settle it")
    func forgetsAResumedWithdrawalPastItsTimeOnAnUnsettledAnswer() async throws {
        let env = makeEnv(recordAnswers: [.success(inProgress())])
        env.store.save(.init(record: inProgress(), deadline: deadline(), settledAt: nil))
        env.clock.now = now.addingTimeInterval(deadlineOffset + settlementGrace + 1)

        await env.sut.resume()
        try await env.state(becomes: nil, after: .inProgress)
        try await drain()

        #expect(try #require(env.states.dropFirst().first) == .inProgress)
        #expect(try #require(env.states.last) == nil)
        #expect(env.store.entry() == nil)
        #expect(env.service.recordRequests == 1)
        #expect(env.delays.heldWaits == [settlementGrace])
    }

    @Test("A withdrawal resumed past its time on a bad network is still polled through the settlement grace")
    func keepsPollingAResumedWithdrawalPastItsTimeThroughFailedRequests() async throws {
        let env = makeEnv(recordAnswers: [.failure(.other(.connection(underlying: URLError(.timedOut))))])
        env.store.save(.init(record: inProgress(), deadline: deadline(), settledAt: nil))
        env.clock.now = now.addingTimeInterval(deadlineOffset + settlementGrace + 1)

        await env.sut.resume()
        try await settle { env.delays.heldWaits == [settlementGrace] && env.service.recordRequests > 1 }

        #expect(env.states == [nil, .inProgress])
        #expect(env.store.entry() != nil)

        env.delays.releaseHeldWaits()
        try await env.state(becomes: nil, after: .inProgress)

        #expect(env.store.entry() == nil)
    }

    // MARK: - Running out of time

    @Test("A withdrawal still in flight past its deadline and the settlement grace is forgotten on the next answer")
    func forgetsAWithdrawalWhoseDeadlineAndGracePassed() async throws {
        let env = makeEnv(recordAnswers: [.success(inProgress())])
        env.service.onRecordRequest = { ordinal in
            if ordinal == 2 {
                env.clock.now = now.addingTimeInterval(deadlineOffset + settlementGrace + 1)
            }
        }

        await env.sut.track(inProgress(), deadline: deadline())
        try await env.state(becomes: nil, after: .inProgress)
        try await drain()

        #expect(env.store.entry() == nil)
        #expect(env.service.recordRequests == 2)
    }

    @Test("The expiry timer is armed for the deadline plus the settlement grace and forgets the withdrawal when it fires")
    func theExpiryTimerForgetsTheWithdrawal() async throws {
        let env = makeEnv(recordAnswers: [.success(inProgress())])

        await env.sut.track(inProgress(), deadline: deadline())
        try await settle { env.delays.heldWaits == [deadlineOffset + settlementGrace] }

        env.delays.releaseHeldWaits()
        try await env.state(becomes: nil, after: .inProgress)
        try await drain()
        let requestsAfterExpiry = env.service.recordRequests
        try await drain()

        #expect(env.store.entry() == nil)
        #expect(env.service.recordRequests == requestsAfterExpiry)
    }

    @Test("An outcome stays on screen for its notice window and is then forgotten")
    func forgetsAnOutcomeAfterItsNoticeWindow() async throws {
        let env = makeEnv(recordAnswers: [.success(confirmed())])

        await env.sut.track(inProgress(), deadline: deadline())
        try await env.state(becomes: .confirmed)
        try await settle { env.delays.heldWaits.contains(outcomeNoticeLifetime) }

        env.delays.releaseHeldWaits()
        try await env.state(becomes: nil, after: .confirmed)

        #expect(env.store.entry() == nil)
    }

    // MARK: - Disk traffic

    @Test("Answers that change nothing are not written to disk")
    func writesToDiskOnlyWhenTheRecordChanges() async throws {
        let env = makeEnv(recordAnswers: [.success(inProgress()), .success(inProgress()), .success(inProgress()), .success(confirmed())])

        await env.sut.track(inProgress(), deadline: deadline())
        try await env.state(becomes: .confirmed)

        #expect(env.service.recordRequests == 4)
        #expect(env.storage.storeCalls == 2)
    }
}

// MARK: - Fixtures

private extension PolymarketWithdrawTrackerTests {
    final class Env {
        let sut: PolymarketWithdrawTracker
        let service: PolymarketWithdrawServiceSpy
        let store: PolymarketWithdrawRecordStore
        let storage: InMemoryPersistentStorage
        let delays: HoldingDelayProviderSpy
        let clock: ClockStub
        let serverClock: PolymarketServerClock

        private let log = OSAllocatedUnfairLock(initialState: [PolymarketWithdrawState?]())
        private var subscription: AnyCancellable?

        init(
            sut: PolymarketWithdrawTracker,
            service: PolymarketWithdrawServiceSpy,
            store: PolymarketWithdrawRecordStore,
            storage: InMemoryPersistentStorage,
            delays: HoldingDelayProviderSpy,
            clock: ClockStub,
            serverClock: PolymarketServerClock
        ) {
            self.sut = sut
            self.service = service
            self.store = store
            self.storage = storage
            self.delays = delays
            self.clock = clock
            self.serverClock = serverClock

            subscription = sut.statePublisher.sink { [log] state in
                log.withLock { $0.append(state) }
            }
        }

        var states: [PolymarketWithdrawState?] {
            log.withLock { $0 }
        }

        func state(becomes expected: PolymarketWithdrawState?, after earlier: PolymarketWithdrawState? = nil) async throws {
            let publisher = sut.statePublisher
            let log = log

            _ = try await Task.run(withTimeout: .seconds(5)) {
                _ = try await publisher
                    .filter { state in
                        guard state == expected else { return false }
                        guard let earlier else { return true }

                        return log.withLock { $0.contains(earlier) }
                    }
                    .eraseToAnyPublisher()
                    .async()
            }.value
        }
    }

    final class ClockStub {
        var now: Date {
            get { state.withLock { $0 } }
            set { state.withLock { $0 = newValue } }
        }

        private let state: OSAllocatedUnfairLock<Date>

        init(now: Date) {
            state = OSAllocatedUnfairLock(initialState: now)
        }
    }

    func makeEnv(recordAnswers: [PolymarketWithdrawServiceSpy.Answer] = []) -> Env {
        let service = PolymarketWithdrawServiceSpy(recordAnswers: recordAnswers)
        let storage = InMemoryPersistentStorage()
        let store = PolymarketWithdrawRecordStore(userWalletId: UserWalletId(value: Data([0x01])), storage: storage)
        let delays = HoldingDelayProviderSpy()
        let clock = ClockStub(now: now)
        let serverClock = PolymarketServerClock(deviceNow: { clock.now })

        let sut = PolymarketWithdrawTracker(
            withdrawService: service,
            store: store,
            delayProvider: delays,
            serverClock: serverClock
        )

        return Env(sut: sut, service: service, store: store, storage: storage, delays: delays, clock: clock, serverClock: serverClock)
    }

    func deadline() -> Date {
        now.addingTimeInterval(deadlineOffset)
    }

    func inProgress(transactionId: String = "tx-1") -> PolymarketWithdrawRecord {
        PolymarketWithdrawRecord(transactionId: transactionId, state: .inProgress, transactionHash: nil)
    }

    func confirmed(transactionId: String = "tx-1") -> PolymarketWithdrawRecord {
        PolymarketWithdrawRecord(transactionId: transactionId, state: .confirmed, transactionHash: "0x7ae1")
    }

    func failed(transactionId: String = "tx-1") -> PolymarketWithdrawRecord {
        PolymarketWithdrawRecord(transactionId: transactionId, state: .failed, transactionHash: nil)
    }
}
