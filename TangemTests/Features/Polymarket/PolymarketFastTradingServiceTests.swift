//
//  PolymarketFastTradingServiceTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import TangemFoundation
import TangemPolymarket
@testable import Tangem

@MainActor
@Suite("Polymarket fast trading service", .timeLimit(.minutes(1)))
struct PolymarketFastTradingServiceTests {
    @Test("A revoking key the backend leaves out of the list for no more than the tolerated reads keeps holding activation, and each return starts the count over")
    func briefGapKeepsTheSettlingKey() async {
        let revoking = Fixture.key(.otherDevice, status: .revoking)
        let gap = Array(repeating: [PolymarketSessionKey](), count: PolymarketSessionKey.settlingMissTolerance)
        let lists = [[revoking]] + gap + [[revoking]] + gap
        let (sut, _, _) = makeSUT(lists: lists)

        for _ in lists {
            await sut.refresh()

            #expect(sut.status == .waitingForSettlement(revoking))
        }
    }

    @Test("A settling key the backend stops listing for good is dropped once it misses more reads than tolerated")
    func lastingGapDropsTheSettlingKey() async {
        let revoking = Fixture.key(.otherDevice, status: .revoking)
        let (sut, _, _) = makeSUT(lists: [[revoking], []])

        await sut.refresh()

        for _ in 0 ..< PolymarketSessionKey.settlingMissTolerance {
            await sut.refresh()

            #expect(sut.status == .waitingForSettlement(revoking))
        }

        await sut.refresh()

        #expect(sut.status == .offerEnable)
    }

    @Test("A read that answers after a newer one leaves the newer state in place")
    func staleReadKeepsTheNewerState() async {
        let revoking = Fixture.key(.otherDevice, status: .revoking)
        let staleRead = PolymarketHeldCall()
        let (sut, _, _) = makeSUT(lists: [[Fixture.key(.otherDevice)], [revoking]], heldReads: [0: staleRead])

        let stale = Task { await sut.refresh() }
        await staleRead.reached.wait()
        await sut.refresh()
        staleRead.release.open()
        _ = await stale.value

        #expect(sut.status == .waitingForSettlement(revoking))
    }

    @Test("Overlapping reads count one miss for a settling key the backend leaves out")
    func overlappingReadsCountOneMiss() async {
        let revoking = Fixture.key(.otherDevice, status: .revoking)
        let olderRead = PolymarketHeldCall()
        let newerRead = PolymarketHeldCall()
        let (sut, _, _) = makeSUT(lists: [[revoking], []], heldReads: [1: olderRead, 2: newerRead])

        await sut.refresh()

        let older = Task { await sut.refresh() }
        await olderRead.reached.wait()
        let newer = Task { await sut.refresh() }
        await newerRead.reached.wait()
        olderRead.release.open()
        _ = await older.value
        newerRead.release.open()
        _ = await newer.value

        for _ in 1 ..< PolymarketSessionKey.settlingMissTolerance {
            await sut.refresh()
        }

        #expect(sut.status == .waitingForSettlement(revoking))
    }

    @Test("An older read publishes when the newer one fails or is cancelled before publishing", arguments: NewerReadOutcome.allCases)
    func olderReadPublishesWhenTheNewerOneDoesNot(outcome: NewerReadOutcome) async {
        let revoking = Fixture.key(.otherDevice, status: .revoking)
        let olderRead = PolymarketHeldCall()
        let (sut, manager, _) = makeSUT(lists: [[revoking]], heldReads: [0: olderRead])

        let older = Task { await sut.refresh() }
        await olderRead.reached.wait()
        manager.failReads(with: outcome.error)
        await sut.refresh()
        olderRead.release.open()
        _ = await older.value

        #expect(sut.status == .waitingForSettlement(revoking))
    }

    @Test(
        "A first read cancelled on the way leaves the state loading instead of failing it",
        arguments: [PolymarketSessionKeyError.cancelled as Error, CancellationError()]
    )
    func cancelledFirstReadKeepsLoading(_ cancellation: Error) async {
        let (sut, manager, _) = makeSUT(lists: [[]])

        manager.failReads(with: cancellation)
        await sut.refresh()

        #expect(sut.state == .loading)
    }

    @Test("A pending key past its settling time that the backend stops listing is dropped at once")
    func stalePendingKeyIsNotBridged() async {
        let stale = Fixture.key(.otherDevice, status: .pending, createdAt: Fixture.now.addingTimeInterval(-Fixture.hour))
        let (sut, _, _) = makeSUT(lists: [[stale], []])

        await sut.refresh()
        await sut.refresh()

        #expect(sut.assessment?.sessionKeys == [])
    }

    @Test("A settling key is read again once the settling interval passes, until it settles")
    func settlingKeyIsReadAgainUntilItSettles() async throws {
        let revoking = Fixture.key(.otherDevice, status: .revoking)
        let delays = PolymarketSteppedDelayProvider()
        let (sut, _, _) = makeSUT(lists: [[revoking], [Fixture.key(.otherDevice, status: .revoked)]], pollDelayProvider: delays)

        await sut.refresh()

        #expect(try await delays.nextWait() == 3)
        #expect(sut.status == .waitingForSettlement(revoking))

        delays.resume()
        await sut.statePublisher.firstValue { state in
            guard case .loaded(let assessment) = state else { return false }

            return !assessment.hasSettlingChange
        }

        #expect(sut.status == .offerEnable)
    }

    @Test("A key store that can't be read fails the first read instead of offering a new key")
    func unreadableKeyStoreFailsTheFirstRead() async {
        let (sut, _, _) = makeSUT(lists: [[]], heldAddresses: [.failure(PolymarketSessionKeyStoreSpy.ReadError())])

        await sut.refresh()

        #expect(sut.state == .failed)
        #expect(await sut.banner() == nil)
    }

    @Test("A key store that stops being readable keeps the last state instead of offering to replace the key")
    func unreadableKeyStoreKeepsTheLastState() async {
        let own = Fixture.key(.local)
        let (sut, _, _) = makeSUT(
            lists: [[own]],
            heldAddresses: [.success(Fixture.localAddress), .failure(PolymarketSessionKeyStoreSpy.ReadError())],
            exchangeSigners: [.matching(own)]
        )

        await sut.refresh()
        await sut.refresh()

        #expect(sut.status == .active(own))
        #expect(await sut.banner() == nil)
    }

    @Test("The activation hands control back once the card has signed and stays in flight until the backend answers")
    func activationReturnsAfterSigning() async throws {
        let (sut, manager, _) = makeSUT(lists: [[]], enable: .signsThenWaits)

        await sut.refresh()

        #expect(await sut.banner() == .activate)

        try await sut.authorize(.enable)

        #expect(sut.assessment?.operations == [.activation])
        #expect(await sut.banner() == nil)

        try await manager.enableSuspended.next()
        manager.failPendingEnable()
        await sut.settled()

        #expect(sut.assessment?.operations == [])
        #expect(await sut.banner() == .activate)
    }

    @Test(
        "Each authorization runs the card operation it stands for",
        arguments: zip(
            [
                PolymarketFastTradingAuthorization.enable,
                .reenable,
                .renew,
                .repair,
                .replace(previous: Fixture.key(.previous), revokesPrevious: true),
                .replace(previous: Fixture.key(.previous), revokesPrevious: false),
            ],
            [
                AuthorizationCall.enable,
                .enable,
                .renew,
                .repair,
                .replace(previousAddress: Fixture.Owner.previous.address, revokesPrevious: true),
                .replace(previousAddress: Fixture.Owner.previous.address, revokesPrevious: false),
            ]
        )
    )
    func authorizationRunsItsOperation(_ authorization: PolymarketFastTradingAuthorization, _ call: AuthorizationCall) async {
        let (sut, manager, _) = makeSUT(lists: [[]])

        await sut.refresh()

        await #expect(throws: (any Error).self) {
            try await sut.authorize(authorization)
        }

        await sut.settled()

        #expect(manager.authorizations == [call])
    }

    @Test("A failure after the card has signed is reported to the screens as a failed activation instead of the closed activation")
    func failureAfterSigningIsReported() async throws {
        let (sut, _, _) = makeSUT(lists: [[]], enable: .signsThenFails)
        let failures = TestSignal<PolymarketFastTradingFailure>()
        let subscription = sut.failurePublisher.sink { failures.send($0) }

        await sut.refresh()
        try await sut.authorize(.enable)

        #expect(try await failures.next() == .activationFailed)

        subscription.cancel()
    }

    @Test("A failure before the card signs reaches the activation screen instead of the other screens")
    func failureBeforeSigningIsThrown() async {
        let (sut, _, _) = makeSUT(lists: [[]], enable: .failsBeforeSigning)
        let failures = TestSignal<PolymarketFastTradingFailure>()
        let subscription = sut.failurePublisher.sink { failures.send($0) }

        await sut.refresh()

        await #expect(throws: (any Error).self) {
            try await sut.authorize(.enable)
        }

        await sut.settled()

        #expect(failures.recorded.isEmpty)

        subscription.cancel()
    }

    @Test("A failure of the authorization signed during onboarding is left to onboarding to report")
    func presignedAuthorizationFailureIsNotReported() async throws {
        let (sut, _, _) = makeSUT(lists: [[]])
        let failures = TestSignal<PolymarketFastTradingFailure>()
        let subscription = sut.failurePublisher.sink { failures.send($0) }
        let grant = try PolymarketSessionKeyCalls.authorize(
            sessionKeyAddress: Fixture.localAddress,
            depositWalletAddress: Self.depositWalletAddress,
            now: Fixture.now
        )
        let batch = PolymarketRelayedBatch(
            ownerAddress: PolymarketOwnerAddressProviderStub.ownerAddress,
            depositWalletAddress: Self.depositWalletAddress,
            nonce: "0",
            deadline: "0",
            calls: [grant.call],
            signature: "0xbatch"
        )

        await sut.refresh()

        await #expect(throws: (any Error).self) {
            try await sut.authorize(presigned: batch, grant: grant)
        }

        sut.reportFailure(.busy)

        #expect(try await failures.next() == .busy)

        subscription.cancel()
    }

    @Test("A revocation whose follow-up read fails shows the key as revoking, not as active")
    func revocationSurvivesAFailedRead() async throws {
        let revoking = Fixture.key(.otherDevice, status: .revoking)
        let (sut, manager, _) = makeSUT(lists: [[Fixture.key(.otherDevice)]], revoked: revoking)

        await sut.refresh()
        manager.failReads(with: URLError(.notConnectedToInternet))
        try await sut.revoke(sessionKeyAddress: revoking.address)

        #expect(sut.status == .waitingForSettlement(revoking))
    }

    @Test(
        "A device revocation this app sent is reported when sent and once more when it settles",
        arguments: zip([Fixture.key(.otherDevice, status: .revoked), Fixture.key(.otherDevice)], [PolymarketFastTradingRevocation.succeeded, .failed])
    )
    func revocationReportsHowItSettled(_ settled: PolymarketSessionKey, _ outcome: PolymarketFastTradingRevocation) async throws {
        let revoking = Fixture.key(.otherDevice, status: .revoking)
        let (sut, _, _) = makeSUT(lists: [[Fixture.key(.otherDevice)], [revoking], [settled]], revoked: revoking)
        let revocations = TestSignal<PolymarketFastTradingRevocation>()
        let subscription = sut.revocationPublisher.sink { revocations.send($0) }

        await sut.refresh()
        try await sut.revoke(sessionKeyAddress: revoking.address)

        #expect(revocations.recorded == [.submitted])

        await sut.refresh()
        await sut.refresh()

        #expect(revocations.recorded == [.submitted, outcome])

        subscription.cancel()
    }

    @Test(
        "A revocation settles by all records of the address, or by the exchange's list when the address had no live record of ours",
        arguments: [
            (
                [
                    [Fixture.key(.otherDevice), Fixture.key(.otherDevice, status: .expired)],
                    [Fixture.key(.otherDevice, status: .expired), Fixture.key(.otherDevice, status: .revoking)],
                    [Fixture.key(.otherDevice, status: .expired), Fixture.key(.otherDevice, status: .revoked)],
                ],
                [PolymarketSessionSigner](),
                PolymarketFastTradingRevocation.succeeded
            ),
            (
                [[], [Fixture.key(.otherDevice, status: .revoking)], []],
                [PolymarketSessionSigner.matching(Fixture.key(.otherDevice))],
                .failed
            ),
            (
                [[], [Fixture.key(.otherDevice, status: .revoking)], [Fixture.key(.otherDevice, status: .revoked)]],
                [],
                .succeeded
            ),
        ]
    )
    func revocationSettlesByEveryRecordOrTheExchange(
        _ lists: [[PolymarketSessionKey]],
        _ signers: [PolymarketSessionSigner],
        _ outcome: PolymarketFastTradingRevocation
    ) async throws {
        let revoking = Fixture.key(.otherDevice, status: .revoking)
        let (sut, _, _) = makeSUT(lists: lists, exchangeSigners: signers, revoked: revoking)
        let revocations = TestSignal<PolymarketFastTradingRevocation>()
        let subscription = sut.revocationPublisher.sink { revocations.send($0) }

        await sut.refresh()
        try await sut.revoke(sessionKeyAddress: revoking.address)

        for _ in 0 ... PolymarketSessionKey.settlingMissTolerance {
            await sut.refresh()
        }

        #expect(revocations.recorded == [.submitted, outcome])

        subscription.cancel()
    }

    @Test("A revocation of a signer with no live record of ours that the exchange still lists stays undecided while it shows as being revoked, then fails")
    func unknownSignerStillListedFailsOnlyOnceItStopsBeingRevoked() async throws {
        let revoked = Fixture.key(.otherDevice, status: .revoked)
        let clock = OSAllocatedUnfairLock(initialState: Fixture.now)
        let (sut, _, _) = makeSUT(
            lists: [[revoked], [Fixture.key(.otherDevice, status: .revoking)], [revoked]],
            exchangeSigners: [.matching(Fixture.key(.otherDevice))],
            revoked: Fixture.key(.otherDevice, status: .revoking),
            now: { clock.withLock { $0 } }
        )
        let revocations = TestSignal<PolymarketFastTradingRevocation>()
        let subscription = sut.revocationPublisher.sink { revocations.send($0) }

        await sut.refresh()
        try await sut.revoke(sessionKeyAddress: revoked.address)
        await sut.refresh()

        #expect(revocations.recorded == [.submitted])
        #expect(sut.assessment?.signersBeingRevoked.map(\.address) == [revoked.address])

        clock.withLock { $0 = Fixture.now.addingTimeInterval(PolymarketSessionKey.backendHoldWindow) }
        await sut.refresh()

        #expect(revocations.recorded == [.submitted, .failed])
        #expect(sut.assessment?.foreignSigners.map(\.address) == [revoked.address])

        subscription.cancel()
    }

    @Test(
        "A revocation that fails says the wallet is busy when another change holds it, and reports a failed revocation otherwise",
        arguments: [
            (PolymarketSessionKeyManagerError.operationInProgress as Error, [PolymarketFastTradingFailure.busy], [PolymarketFastTradingRevocation]()),
            (URLError(.notConnectedToInternet) as Error, [], [.failed]),
        ]
    )
    func failedRevocationReportsItsCause(
        _ error: Error,
        _ failures: [PolymarketFastTradingFailure],
        _ revocations: [PolymarketFastTradingRevocation]
    ) async {
        let other = Fixture.key(.otherDevice)
        let (sut, _, _) = makeSUT(lists: [[other]], revokeFailure: error)
        let reportedFailures = TestSignal<PolymarketFastTradingFailure>()
        let reportedRevocations = TestSignal<PolymarketFastTradingRevocation>()
        let failureSubscription = sut.failurePublisher.sink { reportedFailures.send($0) }
        let revocationSubscription = sut.revocationPublisher.sink { reportedRevocations.send($0) }

        await #expect(throws: (any Error).self) {
            try await sut.revoke(sessionKeyAddress: other.address)
        }

        #expect(reportedFailures.recorded == failures)
        #expect(reportedRevocations.recorded == revocations)

        failureSubscription.cancel()
        revocationSubscription.cancel()
    }

    @Test("An activation whose follow-up read fails shows the new key instead of offering to activate again")
    func activationSurvivesAFailedRead() async throws {
        let own = Fixture.key(.local)
        let (sut, manager, _) = makeSUT(
            lists: [[]],
            enable: .signsThenSucceeds(own),
            heldAddresses: [.success(Fixture.localAddress)],
            exchangeSigners: [.matching(own)]
        )

        await sut.refresh()
        manager.failReads(with: URLError(.notConnectedToInternet))
        try await sut.authorize(.enable)
        await sut.settled()

        #expect(sut.status == .active(own))
    }

    @Test("A failure nobody listened for reaches the next screen that listens, once")
    func unheardFailureReachesTheNextListenerOnce() async throws {
        let (sut, _, _) = makeSUT(lists: [[]], enable: .signsThenFails)

        await sut.refresh()
        try await sut.authorize(.enable)
        await sut.settled()

        let failures = TestSignal<PolymarketFastTradingFailure>()
        let first = sut.failurePublisher.sink { failures.send($0) }

        #expect(try await failures.next() == .activationFailed)

        first.cancel()

        let later = TestSignal<PolymarketFastTradingFailure>()
        let second = sut.failurePublisher.sink { later.send($0) }

        #expect(later.recorded.isEmpty)

        second.cancel()
    }

    @Test("A read cancelled while the exchange's signers load publishes no assessment")
    func cancelledSignersReadPublishesNoAssessment() async {
        let (sut, _, _) = makeSUT(
            lists: [[Fixture.key(.local)]],
            heldAddresses: [.success(Fixture.localAddress)],
            exchangeSignersFailure: CancellationError()
        )

        await sut.refresh()

        #expect(sut.state == .loading)
    }

    @Test("An authorization cut off earlier is sent again after the first read and its key shows up")
    func interruptedAuthorizationIsResumedAfterTheFirstRead() async throws {
        let own = Fixture.key(.local)
        let (sut, manager, _) = makeSUT(
            lists: [[], [own]],
            heldAddresses: [.success(Fixture.localAddress)],
            exchangeSigners: [.matching(own)],
            interrupted: Interruption(resumedKey: own)
        )

        await sut.refresh()
        try await manager.resumed.next()
        await sut.settled()

        #expect(sut.status == .active(own))
    }

    @Test("Closing a banner stores when it was closed for this wallet and hides it from the screens showing it")
    func closingTheBannerHidesIt() async throws {
        let (sut, _, dismissals) = makeSUT(lists: [[]])
        let banners = TestSignal<PolymarketFastTradingBanner?>()
        let subscription = sut.bannerPublisher().sink { banners.send($0) }

        await sut.refresh()
        try await banners.next(where: { $0 == .activate })

        sut.dismissBanner(.activate)

        #expect(try await banners.next() == nil)
        #expect(dismissals.recorded == [.init(kind: .activate, userWalletId: Self.userWalletId, date: Fixture.now)])

        subscription.cancel()
    }

    @Test("A successful activation forgets the banners closed before it")
    func activationForgetsClosedBanners() async throws {
        let own = Fixture.key(.local)
        let (sut, _, dismissals) = makeSUT(
            lists: [[]],
            enable: .signsThenSucceeds(own),
            heldAddresses: [.success(Fixture.localAddress)],
            exchangeSigners: [.matching(own)]
        )

        await sut.refresh()
        sut.dismissBanner(.activate)
        try await sut.authorize(.enable)
        await sut.settled()

        #expect(dismissals.recorded.isEmpty)
    }

    @Test("A resumed authorization forgets the banners closed before it")
    func resumedAuthorizationForgetsClosedBanners() async throws {
        let own = Fixture.key(.local)
        let (sut, manager, dismissals) = makeSUT(
            lists: [[], [own]],
            heldAddresses: [.success(Fixture.localAddress)],
            exchangeSigners: [.matching(own)],
            interrupted: Interruption(resumedKey: own)
        )

        sut.dismissBanner(.activate)
        await sut.refresh()
        try await manager.resumed.next()
        await sut.settled()

        #expect(dismissals.recorded.isEmpty)
    }

    @Test("A key the backend recorded revoked but the exchange still lists is reported foreign, since it can still trade")
    func revokedKeyStillOnTheExchangeIsForeign() async {
        let revoked = Fixture.key(.otherDevice, status: .revoked)
        let (sut, _, _) = makeSUT(lists: [[revoked]], exchangeSigners: [.matching(revoked)])

        await sut.refresh()

        #expect(sut.assessment?.foreignSigners.map(\.address) == [revoked.address])
        #expect(await sut.banner() == .foreignSigners)
    }

    @Test("A key another device has been revoking for longer than its revocation can run stops holding the activation")
    func revokingKeyStopsHoldingOnceItsRevocationCanNoLongerRun() async {
        let revoking = Fixture.key(.otherDevice, status: .revoking)
        let clock = OSAllocatedUnfairLock(initialState: Fixture.now)
        let (sut, _, _) = makeSUT(lists: [[revoking]], now: { clock.withLock { $0 } })

        await sut.refresh()

        #expect(sut.status == .waitingForSettlement(revoking))

        clock.withLock { $0 = $0.addingTimeInterval(Fixture.batchExecutionWindow) }
        await sut.refresh()

        #expect(sut.status == .offerEnable)
    }

    @Test("A refusal keeps this device's key from showing as active while a read can't confirm the key")
    func unconfirmedRefusalHoldsTheKey() async {
        let own = Fixture.key(.local)
        let router = PolymarketOrderSigningRouterSpy(refusals: [Fixture.localAddress: .routed(on: own)])
        let (sut, _, _) = makeSUT(lists: [[own]], heldAddresses: [.success(Fixture.localAddress)], signingRouter: router)

        await sut.refresh()

        #expect(sut.status == .exchangeUnreadable(own))
        #expect(router.invalidated.isEmpty)
    }

    @Test(
        "A refusal is dropped only by a read started after it that shows the key with other terms",
        arguments: zip(
            [
                (Fixture.validUntil.addingTimeInterval(-Fixture.day), Fixture.now.addingTimeInterval(-60)),
                (Fixture.validUntil, Fixture.now.addingTimeInterval(-60)),
                (Fixture.validUntil.addingTimeInterval(-Fixture.day), Fixture.now),
            ],
            [true, false, false]
        )
    )
    func refusalIsDroppedByALaterReadOfOtherTerms(_ refusal: (validUntil: Date, refusedAt: Date), _ isDropped: Bool) async {
        let refusedOn = Fixture.key(.local, validUntil: refusal.validUntil, authorizedAt: Fixture.now.addingTimeInterval(-2 * Fixture.day))
        let own = Fixture.key(.local)
        let router = PolymarketOrderSigningRouterSpy(refusals: [Fixture.localAddress: .routed(on: refusedOn, at: refusal.refusedAt)])
        let (sut, _, _) = makeSUT(
            lists: [[own]],
            heldAddresses: [.success(Fixture.localAddress)],
            exchangeSigners: [.matching(own)],
            signingRouter: router
        )

        await sut.refresh()

        #expect(sut.status == (isDropped ? .active(own) : .repairByRenewal(own)))
        #expect(router.invalidated == (isDropped ? [Fixture.localAddress] : []))
    }

    @Test("A refusal lifted after the last read shows the key active even when the next read fails")
    func liftedRefusalSurvivesAFailedRead() async throws {
        let own = Fixture.key(.local)
        let router = PolymarketOrderSigningRouterSpy(refusals: [Fixture.localAddress: .routed(on: own)])
        let (sut, manager, _) = makeSUT(
            lists: [[own]],
            heldAddresses: [.success(Fixture.localAddress)],
            exchangeSigners: [.matching(own)],
            signingRouter: router
        )

        await sut.refresh()
        try #require(sut.status == .repairByRenewal(own))

        await router.invalidate(sessionKeyAddress: Fixture.localAddress)
        manager.failReads(with: URLError(.notConnectedToInternet))
        await sut.refresh()

        #expect(sut.status == .active(own))
    }

    @Test("A renewed key the exchange keeps listing is not taken for a revoked one waiting to be delisted")
    func renewedKeyDoesNotAwaitDelisting() async {
        let renewed = Fixture.key(.local, validUntil: Fixture.validUntil.addingTimeInterval(Fixture.day))
        let (sut, _, _) = makeSUT(
            lists: [[Fixture.key(.local)], [Fixture.key(.local, status: .revoked), renewed]],
            heldAddresses: [.success(Fixture.localAddress)],
            exchangeSigners: [.matching(renewed)]
        )

        await sut.refresh()
        await sut.refresh()

        #expect(sut.status == .active(renewed))
        #expect(sut.assessment?.needsFollowUpReads == false)
    }

    @Test("An authorization cut off after the first read is still sent again on a later read")
    func authorizationInterruptedLaterIsResent() async throws {
        let own = Fixture.key(.local)
        let (sut, manager, _) = makeSUT(lists: [[]])

        await sut.refresh()
        try await manager.resumeChecks.next()

        manager.interrupt(Interruption(resumedKey: own))
        await sut.refresh()

        try await manager.resumed.next()
    }

    @Test("An authorization that could not be sent yet waits for its backoff when an operation ends in between, and is sent again after it even while reads fail")
    func unsentAuthorizationWaitsForItsBackoffAfterAnOperation() async throws {
        let own = Fixture.key(.local)
        let delays = HoldingDelayProviderSpy(holdThreshold: 0)
        let (sut, manager, _) = makeSUT(
            lists: [[]],
            interrupted: Interruption(resumedKey: own, failures: [PolymarketSessionKeyManagerError.unsettled(own)]),
            pollDelayProvider: delays
        )

        await sut.refresh()
        try await manager.resumed.next()
        await sut.settled()
        manager.failReads(with: URLError(.notConnectedToInternet))

        await #expect(throws: (any Error).self) {
            try await sut.setEnabled(false, sessionKeyAddress: own.address)
        }

        await Task { @MainActor in }.value

        #expect(manager.resumed.recorded.count == 1)

        delays.releaseHeldWaits()

        try await manager.resumed.next()
    }

    @Test("Reads do not send an interrupted authorization again before its backoff, and it is tried three times at most")
    func readsKeepTheResumeBackoffAndLimit() async throws {
        let own = Fixture.key(.local)
        let delays = PolymarketSteppedDelayProvider()
        let unsettled = PolymarketSessionKeyManagerError.unsettled(own)
        let (sut, manager, _) = makeSUT(
            lists: [[]],
            interrupted: Interruption(resumedKey: own, failures: Array(repeating: unsettled, count: 4)),
            pollDelayProvider: delays
        )

        await sut.refresh()
        try await manager.resumed.next()
        try await delays.nextWait(of: Self.resumeRetryDelay)

        await sut.refresh()
        await sut.refresh()
        await Task { @MainActor in }.value

        #expect(manager.resumed.recorded.count == 1)

        delays.resume(Self.resumeRetryDelay)
        try await manager.resumed.next()
        try await delays.nextWait(of: 2 * Self.resumeRetryDelay)
        delays.resume(2 * Self.resumeRetryDelay)
        try await manager.resumed.next()

        await sut.settled()
        await sut.refresh()
        await Task { @MainActor in }.value

        #expect(manager.resumed.recorded.count == 3)
        #expect(delays.parkedWaits.isEmpty)
    }

    @Test("An exchange list that can't be read shows as a failed read at once and is not read again on its own")
    func unreadableExchangeListIsNotPolled() async {
        let failed = Fixture.key(.local, status: .failed)
        let delays = ClockedDelayProviderSpy(start: Fixture.now)
        let (sut, _, _) = makeSUT(
            lists: [[failed]],
            heldAddresses: [.success(Fixture.localAddress)],
            exchangeSignersFailure: URLError(.badServerResponse),
            pollDelayProvider: delays
        )

        await sut.refresh()

        #expect(sut.status == .exchangeUnreadable(failed))
        #expect(delays.waits.isEmpty)
    }

    @Test(
        "An authorization sent again after it was cut off shows as the operation it was signed for, so a repair of this device's key shows as an activation",
        arguments: zip([PolymarketInterruptedAuthorization.Purpose.renewal, .activation], [PolymarketFastTradingOperation.renewal, .activation])
    )
    func resentAuthorizationShowsItsOperation(_ purpose: PolymarketInterruptedAuthorization.Purpose, _ operation: PolymarketFastTradingOperation) async throws {
        let own = Fixture.key(.local)
        let (sut, manager, _) = makeSUT(
            lists: [[own]],
            heldAddresses: [.success(Fixture.localAddress)],
            exchangeSigners: [.matching(own)],
            interrupted: Interruption(resumedKey: own, revokedAddress: Fixture.localAddress, purpose: purpose)
        )
        let published = TestSignal<[PolymarketFastTradingOperation]>()
        let subscription = sut.statePublisher.sink { state in
            if case .loaded(let assessment) = state {
                published.send(assessment.operations)
            }
        }

        await sut.refresh()
        try await manager.resumed.next()
        await sut.settled()

        #expect(published.recorded.contains([operation]))
        #expect(published.recorded.filter { !$0.isEmpty }.allSatisfy { $0 == [operation] })

        subscription.cancel()
    }

    @Test("A read started before a revocation that answers after it leaves the key revoking")
    func readStartedBeforeARevocationDoesNotUndoIt() async throws {
        let other = Fixture.key(.otherDevice)
        let revoking = Fixture.key(.otherDevice, status: .revoking)
        let staleRead = PolymarketHeldCall()
        let (sut, manager, _) = makeSUT(lists: [[other]], heldReads: [1: staleRead], revoked: revoking)

        await sut.refresh()

        let stale = Task { await sut.refresh() }
        await staleRead.reached.wait()
        manager.failReads(with: URLError(.notConnectedToInternet))
        try await sut.revoke(sessionKeyAddress: other.address)
        staleRead.release.open()
        _ = await stale.value

        #expect(sut.status == .waitingForSettlement(revoking))
    }

    @Test("This device's pending key is read again every few seconds, then less often, and no more once the backend stops holding it pending")
    func pendingKeyIsFollowedUntilTheBackendDropsIt() async throws {
        let pending = Fixture.key(.local, status: .pending)
        let delays = ClockedDelayProviderSpy(start: Fixture.now)
        let (sut, _, _) = makeSUT(
            lists: [[pending]],
            heldAddresses: [.success(Fixture.localAddress)],
            pollDelayProvider: delays,
            now: { delays.now }
        )
        let pendingAtStart = try #require(pending.createdAt.map(Fixture.now.timeIntervalSince))
        let slowReads = Int(((Fixture.batchExecutionWindow - pendingAtStart - Self.fastSettlingPhase) / Self.slowSettlingInterval).rounded(.up))

        await sut.refresh()
        await sut.statePublisher.firstValue { state in
            guard case .loaded(let assessment) = state else { return false }

            return !assessment.needsFollowUpReads
        }

        #expect(delays.waits == Self.fastSettlingWaits + Array(repeating: Self.slowSettlingInterval, count: slowReads))
        #expect(sut.status == .reenable(pending))
    }

    @Test("A repair shows as an activation in flight, as its progress message says, not as an extension")
    func repairShowsAsActivation() async throws {
        let (sut, _, _) = makeSUT(lists: [[]])
        let published = TestSignal<[PolymarketFastTradingOperation]>()
        let subscription = sut.statePublisher.sink { state in
            if case .loaded(let assessment) = state {
                published.send(assessment.operations)
            }
        }

        await sut.refresh()

        await #expect(throws: (any Error).self) {
            try await sut.authorize(.repair)
        }

        await sut.settled()

        #expect(published.recorded.contains([.activation]))
        #expect(!published.recorded.contains([.renewal]))

        subscription.cancel()
    }

    @Test("An interrupted authorization that failed for good stays kept but is not sent again on its own, while one interrupted later still is")
    func failedInterruptedAuthorizationStaysKeptUnsent() async throws {
        let own = Fixture.key(.local)
        let (sut, manager, _) = makeSUT(
            lists: [[]],
            interrupted: Interruption(resumedKey: own, failures: [PolymarketSessionKeyManagerError.missingSessionKey])
        )

        await sut.refresh()
        try await manager.resumed.next()
        await sut.settled()

        await sut.refresh()
        try await manager.resumeChecks.waitForCount(2)
        await Task { @MainActor in }.value

        #expect(manager.resumed.recorded.count == 1)
        #expect(manager.keptSignature == "0xbatch")

        manager.interrupt(Interruption(resumedKey: own, signature: "0xlater"))
        await sut.refresh()

        try await manager.resumed.next()

        #expect(manager.resumed.recorded.count == 2)
    }

    @Test("A key this device revoked that the exchange still lists shows as being revoked for half an hour, then as a foreign signer")
    func ownRevocationStillOnTheExchangeIsForeignOnlyAfterHalfAnHour() async throws {
        let other = Fixture.key(.otherDevice)
        let revoked = Fixture.key(.otherDevice, status: .revoked)
        let clock = OSAllocatedUnfairLock(initialState: Fixture.now)
        let (sut, _, _) = makeSUT(
            lists: [[other], [revoked]],
            exchangeSigners: [.matching(other)],
            revoked: Fixture.key(.otherDevice, status: .revoking),
            now: { clock.withLock { $0 } }
        )

        await sut.refresh()
        try await sut.revoke(sessionKeyAddress: other.address)

        #expect(sut.assessment?.signersBeingRevoked.map(\.address) == [other.address])
        #expect(sut.assessment?.foreignSigners.isEmpty == true)
        #expect(await sut.banner() != .foreignSigners)

        clock.withLock { $0 = Fixture.now.addingTimeInterval(30 * 60) }
        await sut.refresh()

        #expect(sut.assessment?.signersBeingRevoked.isEmpty == true)
        #expect(sut.assessment?.foreignSigners.map(\.address) == [other.address])
    }

    @Test(
        "This device's key revoked for a re-authorization kept for a resend shows as being revoked, not as an unknown signer, whether signed now or before a restart",
        arguments: [false, true]
    )
    func keptReauthorizationShowsItsRevokedKeyAsBeingRevoked(_ isKeptBeforeRestart: Bool) async throws {
        let revoked = Fixture.key(.local, status: .revoked)
        let kept = Interruption(resumedKey: Fixture.key(.local), revokedAddress: revoked.address, failures: [Self.relayerBusy], deadline: Self.executableDeadline)
        let (sut, manager, _) = makeSUT(
            lists: [[revoked]],
            enable: .signsThenKeepsForResend(kept, failure: Self.relayerBusy),
            heldAddresses: [.success(Fixture.localAddress)],
            exchangeSigners: [.matching(revoked)],
            interrupted: isKeptBeforeRestart ? kept : nil
        )
        let foreignSigners = TestSignal<[String]>()
        let subscription = sut.statePublisher.sink { state in
            if case .loaded(let assessment) = state {
                foreignSigners.send(assessment.foreignSigners.map(\.address))
            }
        }

        await sut.refresh()

        if !isKeptBeforeRestart {
            try await sut.authorize(.enable)
        }

        try await manager.resumed.next()
        await sut.settled()

        #expect(foreignSigners.recorded.dropFirst().allSatisfy { $0.isEmpty })
        #expect(sut.assessment?.signersBeingRevoked.map(\.address) == [revoked.address])

        subscription.cancel()
    }

    @Test(
        "An interrupted authorization that could not be completed yet is tried again after a short wait, each time a little later",
        arguments: [
            PolymarketSessionKeyManagerError.unsettled(Fixture.key(.local)) as Error,
            PolymarketAPIError.http(statusCode: 503, problemDetail: nil),
            PolymarketAPIError.connection(underlying: URLError(.networkConnectionLost)),
            PolymarketSessionKeyManagerError.operationInProgress,
        ]
    )
    func incompleteInterruptedAuthorizationIsRetried(_ failure: Error) async throws {
        let own = Fixture.key(.local)
        let delays = PolymarketSteppedDelayProvider()
        let (sut, manager, _) = makeSUT(
            lists: [[], [own]],
            heldAddresses: [.success(Fixture.localAddress)],
            exchangeSigners: [.matching(own)],
            interrupted: Interruption(resumedKey: own, failures: [failure, failure]),
            pollDelayProvider: delays
        )

        await sut.refresh()

        for wait in [Self.resumeRetryDelay, 2 * Self.resumeRetryDelay] {
            try await delays.nextWait(of: wait)
            delays.resume(wait)
        }

        try await manager.resumed.waitForCount(3)
        await sut.statePublisher.firstValue { state in
            guard case .loaded(let assessment) = state else { return false }

            return assessment.status == .active(own)
        }
    }

    @Test("A signed authorization the relayer refused as busy is kept for a resend and fails only once its resends run out")
    func keptAuthorizationFailsOnlyOnceItsResendsRunOut() async throws {
        let delays = PolymarketSteppedDelayProvider()
        let kept = Interruption(resumedKey: Fixture.key(.local), failures: Array(repeating: Self.relayerBusy, count: 3))
        let (sut, manager, _) = makeSUT(lists: [[]], enable: .signsThenKeepsForResend(kept, failure: Self.relayerBusy), pollDelayProvider: delays)
        let failures = TestSignal<PolymarketFastTradingFailure>()
        let subscription = sut.failurePublisher.sink { failures.send($0) }

        await sut.refresh()
        try await sut.authorize(.enable)

        for wait in [Self.resumeRetryDelay, 2 * Self.resumeRetryDelay] {
            try await delays.nextWait(of: wait)
            #expect(failures.recorded.isEmpty)
            delays.resume(wait)
        }

        #expect(try await failures.next() == .activationFailed)
        #expect(manager.resumed.recorded.count == 3)

        subscription.cancel()
    }

    @Test("A signed authorization kept for a resend fails once the resend finds it dropped")
    func keptAuthorizationFailsOnceDropped() async throws {
        let kept = Interruption(resumedKey: Fixture.key(.local), failures: [PolymarketSessionKeyManagerError.noInterruptedAuthorization])
        let (sut, _, _) = makeSUT(lists: [[]], enable: .signsThenKeepsForResend(kept, failure: Self.relayerBusy))
        let failures = TestSignal<PolymarketFastTradingFailure>()
        let subscription = sut.failurePublisher.sink { failures.send($0) }

        await sut.refresh()
        try await sut.authorize(.enable)

        #expect(try await failures.next() == .activationFailed)

        subscription.cancel()
    }

    @Test("An authorization in flight keeps its service until it ends, so its failure still reaches the screens")
    func inFlightAuthorizationOutlivesItsService() async throws {
        let failures = TestSignal<PolymarketFastTradingFailure>()
        let (manager, subscription) = try await authorizeThenDropTheService(reportingTo: failures)

        manager.failPendingEnable()

        #expect(try await failures.next() == .activationFailed)

        subscription.cancel()
    }

    @Test("Stopping the work of a deleted wallet's service cancels the authorization still running after the card signed")
    func stoppedWorkCancelsTheSignedAuthorization() async throws {
        let (sut, manager, _) = makeSUT(lists: [[]], enable: .signsThenWaits)

        await sut.refresh()
        try await sut.authorize(.enable)
        try await manager.enableSuspended.next()

        sut.cancelWork()
        manager.failPendingEnable()

        #expect(try await manager.enableEnds.next() == true)
    }

    @Test("Stopping the work of a deleted wallet's service cancels the resend of a kept authorization still running")
    func stoppedWorkCancelsTheResume() async throws {
        let resume = PolymarketHeldCall()
        let (sut, manager, _) = makeSUT(lists: [[]], interrupted: Interruption(resumedKey: Fixture.key(.local), held: resume))

        await sut.refresh()
        await resume.reached.wait()

        sut.cancelWork()
        resume.release.open()

        #expect(try await manager.resumeEnds.next() == true)
    }
}

// MARK: - Arguments

extension PolymarketFastTradingServiceTests {
    enum AuthorizationCall: Equatable {
        case enable
        case renew
        case repair
        case replace(previousAddress: String, revokesPrevious: Bool)
    }

    enum NewerReadOutcome: CaseIterable {
        case failed
        case cancelled

        var error: Error {
            switch self {
            case .failed:
                URLError(.notConnectedToInternet)
            case .cancelled:
                PolymarketSessionKeyError.cancelled
            }
        }
    }
}

// MARK: - Helpers

private typealias Fixture = PolymarketSessionKeyFixtures
private typealias Interruption = SessionKeyManagerSpy.Interruption

private extension PolymarketFastTradingServiceTests {
    static let userWalletId = UserWalletId(value: Data(repeating: 0x03, count: 32))
    nonisolated static let depositWalletAddress = "0xd000000000000000000000000000000000000001"
    static let settlingInterval: TimeInterval = 3
    static let slowSettlingInterval: TimeInterval = 20
    static let fastSettlingPhase: TimeInterval = 2 * 60
    static let fastSettlingWaits = Array(repeating: settlingInterval, count: Int(fastSettlingPhase / settlingInterval))
    static let resumeRetryDelay: TimeInterval = 10
    static let relayerBusy = PolymarketSessionKeyError.refused(statusCode: 422, reason: .relayerRejected, detail: "wallet has in-flight action")
    static let executableDeadline = String(Int(Fixture.now.timeIntervalSince1970) + PolymarketSessionKeyAuthorizationBatch.followUpDeadlineOffset)

    func makeSUT(
        lists: [[PolymarketSessionKey]],
        heldReads: [Int: PolymarketHeldCall] = [:],
        enable: SessionKeyManagerSpy.EnableBehaviour = .failsBeforeSigning,
        heldAddresses: [Result<String?, Error>] = [.success(nil)],
        exchangeSigners: [PolymarketSessionSigner]? = nil,
        exchangeSignersFailure: Error? = nil,
        revoked: PolymarketSessionKey? = nil,
        revokeFailure: Error? = nil,
        interrupted: SessionKeyManagerSpy.Interruption? = nil,
        pollDelayProvider: PollDelayProvider = HoldingDelayProviderSpy(holdThreshold: 0),
        signingRouter: PolymarketOrderSigningRouterSpy = PolymarketOrderSigningRouterSpy(),
        operationGate: PolymarketWalletOperationGate? = nil,
        keptAuthorizations: PolymarketInterruptedAuthorizationStore? = nil,
        now: @escaping () -> Date = { Fixture.now }
    ) -> (sut: CommonPolymarketFastTradingService, manager: SessionKeyManagerSpy, dismissals: BannerDismissalsSpy) {
        let manager = SessionKeyManagerSpy(
            lists: lists,
            heldReads: heldReads,
            enable: enable,
            revoked: revoked,
            revokeFailure: revokeFailure,
            interrupted: interrupted,
            operationGate: operationGate,
            keptAuthorizations: keptAuthorizations
        )
        let dismissals = BannerDismissalsSpy()
        let ownerAddress = exchangeSigners == nil && exchangeSignersFailure == nil ? nil : PolymarketOwnerAddressProviderStub.ownerAddress
        let signersResult = exchangeSignersFailure.map { Result<[PolymarketSessionSigner], Error>.failure($0) }
            ?? exchangeSigners.map { Result<[PolymarketSessionSigner], Error>.success($0) }

        let sut = CommonPolymarketFastTradingService(
            userWalletId: Self.userWalletId,
            manager: manager,
            keyStore: PolymarketSessionKeyStoreSpy(heldAddresses: heldAddresses),
            deviceIdProvider: PolymarketDeviceIdProviderStub(),
            clobService: PolymarketCLOBServiceStub(sessionSignersResult: signersResult),
            credentialsRepository: PolymarketCredentialsRepositoryStub(stored: PolymarketCredentialsRepositoryStub.credentials),
            ownerAddressProvider: PolymarketOwnerAddressProviderStub(derived: ownerAddress),
            bannerDismissals: dismissals,
            signingRouter: signingRouter,
            pollDelayProvider: pollDelayProvider,
            now: now
        )

        return (sut, manager, dismissals)
    }

    func authorizeThenDropTheService(
        reportingTo failures: TestSignal<PolymarketFastTradingFailure>
    ) async throws -> (manager: SessionKeyManagerSpy, subscription: AnyCancellable) {
        let (sut, manager, _) = makeSUT(lists: [[]], enable: .signsThenWaits)
        let subscription = sut.failurePublisher.sink { failures.send($0) }

        await sut.refresh()
        try await sut.authorize(.enable)
        try await manager.enableSuspended.next()

        return (manager, subscription)
    }
}

private extension PolymarketOrderSigningRefusal {
    static func routed(on sessionKey: PolymarketSessionKey, at refusedAt: Date = Fixture.now.addingTimeInterval(-60)) -> PolymarketOrderSigningRefusal {
        PolymarketOrderSigningRefusal(
            refusedAt: refusedAt,
            routedOn: PolymarketSessionKeyConfirmation(record: sessionKey, signer: .matching(sessionKey))
        )
    }
}

private extension CommonPolymarketFastTradingService {
    var assessment: PolymarketFastTradingAssessment? {
        guard case .loaded(let assessment) = state else { return nil }

        return assessment
    }

    var status: PolymarketFastTradingAssessment.Status? {
        assessment?.status
    }

    func bannerPublisher() -> AnyPublisher<PolymarketFastTradingBanner?, Never> {
        PolymarketFastTradingBannerMapper(includesForeignSigners: true, now: { Fixture.now })
            .mapToBannerPublisher(states: statePublisher, dismissals: bannerDismissalsPublisher)
    }

    func banner() async -> PolymarketFastTradingBanner? {
        await bannerPublisher().firstValue(where: { _ in true })
    }

    func settled() async {
        await statePublisher.firstValue { state in
            guard case .loaded(let assessment) = state else { return false }

            return !assessment.isOperationInFlight
        }
    }
}

// MARK: - Stubs

private final class SessionKeyManagerSpy: PolymarketSessionKeyManaging {
    enum EnableBehaviour {
        case signsThenWaits
        case signsThenFails
        case signsThenKeepsForResend(Interruption, failure: Error)
        case signsThenSucceeds(PolymarketSessionKey)
        case failsBeforeSigning
    }

    struct Interruption {
        let resumedKey: PolymarketSessionKey
        var revokedAddress = Fixture.Owner.previous.address
        var purpose = PolymarketInterruptedAuthorization.Purpose.activation
        var failures: [Error] = []
        var signature = "0xbatch"
        var deadline = "0"
        var held: PolymarketHeldCall?

        var authorization: PolymarketInterruptedAuthorization {
            let call = PolymarketRelayedBatch.Call(target: Fixture.Owner.previous.address, data: "0x")

            return PolymarketInterruptedAuthorization(
                revokedAddress: revokedAddress,
                revocation: PolymarketRelayedBatch(
                    ownerAddress: PolymarketOwnerAddressProviderStub.ownerAddress,
                    depositWalletAddress: PolymarketFastTradingServiceTests.depositWalletAddress,
                    nonce: "7",
                    deadline: "0",
                    calls: [call],
                    signature: "0xrevocation"
                ),
                batch: PolymarketRelayedBatch(
                    ownerAddress: PolymarketOwnerAddressProviderStub.ownerAddress,
                    depositWalletAddress: PolymarketFastTradingServiceTests.depositWalletAddress,
                    nonce: "8",
                    deadline: deadline,
                    calls: [call],
                    signature: signature
                ),
                grant: PolymarketSessionKeyGrant(
                    sessionKeyAddress: resumedKey.address,
                    validUntil: resumedKey.validUntil ?? Fixture.validUntil,
                    call: call
                ),
                deviceId: Fixture.deviceId,
                purpose: purpose
            )
        }
    }

    let enableSuspended = TestSignal<Void>()
    let enableEnds = TestSignal<Bool>()
    let resumeEnds = TestSignal<Bool>()
    let resumed = TestSignal<Void>()
    let resumeChecks = TestSignal<Void>()
    let startedReads = TestSignal<Void>()

    private struct State {
        var lists: [[PolymarketSessionKey]]
        var reads = 0
        var readFailure: Error?
        var pendingEnable: CheckedContinuation<PolymarketSessionKey, Error>?
        var authorizations: [PolymarketFastTradingServiceTests.AuthorizationCall] = []
        var interrupted: Interruption?
    }

    private struct StubError: Error {}

    private let enableBehaviour: EnableBehaviour
    private let heldReads: [Int: PolymarketHeldCall]
    private let revoked: PolymarketSessionKey?
    private let revokeFailure: Error?
    private let operationGate: PolymarketWalletOperationGate?
    private let keptAuthorizations: PolymarketInterruptedAuthorizationStore?
    private let state: OSAllocatedUnfairLock<State>

    init(
        lists: [[PolymarketSessionKey]],
        heldReads: [Int: PolymarketHeldCall],
        enable: EnableBehaviour,
        revoked: PolymarketSessionKey?,
        revokeFailure: Error?,
        interrupted: Interruption?,
        operationGate: PolymarketWalletOperationGate?,
        keptAuthorizations: PolymarketInterruptedAuthorizationStore?
    ) {
        enableBehaviour = enable
        self.heldReads = heldReads
        self.revoked = revoked
        self.revokeFailure = revokeFailure
        self.operationGate = operationGate
        self.keptAuthorizations = keptAuthorizations
        state = OSAllocatedUnfairLock(initialState: State(lists: lists, interrupted: interrupted))
    }

    var authorizations: [PolymarketFastTradingServiceTests.AuthorizationCall] {
        state.withLock { $0.authorizations }
    }

    var keptSignature: String? {
        state.withLock { $0.interrupted?.signature }
    }

    func failPendingEnable() {
        let pending = state.withLock { state in
            defer { state.pendingEnable = nil }
            return state.pendingEnable
        }

        pending?.resume(throwing: StubError())
    }

    func interrupt(_ interruption: Interruption) {
        state.withLock { $0.interrupted = interruption }
    }

    func failReads(with error: Error) {
        state.withLock { $0.readFailure = error }
    }

    func sessionKeys() async throws -> [PolymarketSessionKey] {
        let read = state.withLock { state -> (index: Int, sessionKeys: [PolymarketSessionKey], failure: Error?) in
            defer { state.reads += 1 }

            return (state.reads, state.lists.count > 1 ? state.lists.removeFirst() : (state.lists.first ?? []), state.readFailure)
        }

        startedReads.send()

        await heldReads[read.index]?.pass()

        if let failure = read.failure {
            throw failure
        }

        return read.sessionKeys
    }

    func enable(onSigned: @escaping @Sendable () -> Void) async throws -> PolymarketSessionKey {
        state.withLock { $0.authorizations.append(.enable) }

        switch enableBehaviour {
        case .failsBeforeSigning:
            throw StubError()
        case .signsThenFails:
            onSigned()
            throw StubError()
        case .signsThenKeepsForResend(let interruption, let failure):
            onSigned()
            interrupt(interruption)
            throw failure
        case .signsThenSucceeds(let sessionKey):
            onSigned()

            return sessionKey
        case .signsThenWaits:
            onSigned()

            defer { enableEnds.send(Task.isCancelled) }

            return try await withCheckedThrowingContinuation { continuation in
                state.withLock { $0.pendingEnable = continuation }
                enableSuspended.send(())
            }
        }
    }

    func authorize(presigned batch: PolymarketRelayedBatch, grant: PolymarketSessionKeyGrant) async throws -> PolymarketSessionKey {
        throw StubError()
    }

    func renew(onSigned: @escaping @Sendable () -> Void) async throws -> PolymarketSessionKey {
        state.withLock { $0.authorizations.append(.renew) }

        throw StubError()
    }

    func repair(onSigned: @escaping @Sendable () -> Void) async throws -> PolymarketSessionKey {
        state.withLock { $0.authorizations.append(.repair) }

        throw StubError()
    }

    func replace(
        previousSessionKeyAddress: String,
        revokesPrevious: Bool,
        onSigned: @escaping @Sendable () -> Void
    ) async throws -> PolymarketSessionKey {
        state.withLock { $0.authorizations.append(.replace(previousAddress: previousSessionKeyAddress, revokesPrevious: revokesPrevious)) }

        throw StubError()
    }

    func revoke(sessionKeyAddress: String) async throws -> PolymarketSessionKey {
        guard let revoked else {
            throw revokeFailure ?? StubError()
        }

        return revoked
    }

    func setEnabled(_ isEnabled: Bool, sessionKeyAddress: String) async throws -> PolymarketSessionKey {
        throw StubError()
    }

    @MainActor
    func resumableInterruptedAuthorization() async -> PolymarketInterruptedAuthorization? {
        defer { resumeChecks.send() }

        guard operationGate?.isBusy(PolymarketFastTradingServiceTests.userWalletId) != true else {
            return nil
        }

        return state.withLock { $0.interrupted }?.authorization
    }

    @MainActor
    func resumeInterruptedAuthorization() async throws -> PolymarketSessionKey {
        guard let operationGate else {
            return try await resumeTheKeptAuthorization()
        }

        return try await operationGate.exclusively(
            PolymarketFastTradingServiceTests.userWalletId,
            as: .fastTradingChange,
            orThrow: { _ in PolymarketSessionKeyManagerError.operationInProgress }
        ) {
            try await resumeTheKeptAuthorization()
        }
    }

    @MainActor
    private func resumeTheKeptAuthorization() async throws -> PolymarketSessionKey {
        await state.withLock { $0.interrupted?.held }?.pass()
        resumeEnds.send(Task.isCancelled)

        let outcome = state.withLock { state -> Result<PolymarketSessionKey, Error> in
            guard var interrupted = state.interrupted else {
                return .failure(PolymarketSessionKeyManagerError.noInterruptedAuthorization)
            }

            guard interrupted.failures.isEmpty else {
                let failure = interrupted.failures.removeFirst()
                state.interrupted = interrupted
                return .failure(failure)
            }

            state.interrupted = nil
            return .success(interrupted.resumedKey)
        }

        if case .success = outcome {
            try? keptAuthorizations?.delete(for: PolymarketFastTradingServiceTests.userWalletId)
        }

        resumed.send()

        return try outcome.get()
    }
}

private final class ClockedDelayProviderSpy: PollDelayProvider, Sendable {
    private let state: OSAllocatedUnfairLock<State>

    init(start: Date) {
        state = OSAllocatedUnfairLock(initialState: State(now: start))
    }

    var now: Date {
        state.withLock { $0.now }
    }

    var waits: [TimeInterval] {
        state.withLock { $0.waits }
    }

    func wait(for seconds: TimeInterval) async throws {
        state.withLock { state in
            state.waits.append(seconds)
            state.now = state.now.addingTimeInterval(seconds)
        }
    }

    private struct State {
        var now: Date
        var waits: [TimeInterval] = []
    }
}

private final class BannerDismissalsSpy: PolymarketFastTradingBannerDismissals {
    struct Dismissal: Equatable {
        let kind: PolymarketFastTradingBanner.DismissibleKind
        let userWalletId: UserWalletId
        let date: Date
    }

    private(set) var recorded: [Dismissal] = []

    func dismissalDate(of kind: PolymarketFastTradingBanner.DismissibleKind, userWalletId: UserWalletId) -> Date? {
        recorded.last { $0.kind == kind && $0.userWalletId == userWalletId }?.date
    }

    func setDismissalDate(_ date: Date, of kind: PolymarketFastTradingBanner.DismissibleKind, userWalletId: UserWalletId) {
        recorded.append(Dismissal(kind: kind, userWalletId: userWalletId, date: date))
    }

    func deleteDismissals(userWalletId: UserWalletId) {
        recorded.removeAll { $0.userWalletId == userWalletId }
    }
}
