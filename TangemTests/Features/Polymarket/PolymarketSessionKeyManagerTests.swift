//
//  PolymarketSessionKeyManagerTests.swift
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

@Suite("Polymarket session key manager", .timeLimit(.minutes(1)))
struct PolymarketSessionKeyManagerTests {
    @Test("Enabling signs one authorization for 180 days with the wallet nonce and a ten-minute deadline")
    func enableBuildsTheAuthorization() async throws {
        let keyStore = PolymarketSessionKeyStoreSpy(heldAddress: Self.localAddress)
        let signer = BatchesSignerSpy()
        let service = SessionKeyServiceSpy()
        let sut = try makeSUT(keyStore: keyStore, signer: signer, service: service)

        _ = try await sut.enable()

        let signed = try #require(signer.calls.first)
        let batch = try #require(signed.batches.first)
        let authorization = try #require(service.authorizations.first)

        #expect(signer.calls.count == 1)
        #expect(signed.batches.count == 1)
        #expect(batch.nonce == PolymarketRelayerServiceStub.nonce)
        #expect(batch.deadline == String(Self.nowSeconds + 600))
        #expect(batch.calls.count == 1)
        #expect(authorization.grant.sessionKeyAddress == Self.localAddress)
        #expect(authorization.grant.validUntil == Self.now.addingTimeInterval(180 * 24 * 60 * 60))
        #expect(authorization.deviceId == Self.deviceId)
        #expect(authorization.deviceName == Self.deviceName)
        #expect(authorization.replacesSessionKeyAddress == nil)
        #expect(service.revocations.isEmpty)
        #expect(keyStore.generatedKeys == 0)
    }

    @Test("Enabling on a device without a key creates one and authorizes it")
    func enableCreatesAMissingKey() async throws {
        let keyStore = PolymarketSessionKeyStoreSpy(heldAddress: nil)
        let service = SessionKeyServiceSpy()
        let sut = try makeSUT(keyStore: keyStore, service: service)

        _ = try await sut.enable()

        let authorization = try #require(service.authorizations.first)

        #expect(authorization.grant.sessionKeyAddress == PolymarketSessionKeyStoreSpy.generatedAddress)
        #expect(keyStore.generatedKeys == 1)
    }

    @Test("A key store that can't be read stops enabling before the card tap instead of replacing the key")
    func unreadableKeyStoreStopsEnabling() async throws {
        let keyStore = PolymarketSessionKeyStoreSpy(heldAddresses: [.failure(PolymarketSessionKeyStoreSpy.ReadError())])
        let signer = BatchesSignerSpy()
        let sut = try makeSUT(keyStore: keyStore, signer: signer)

        await #expect(throws: PolymarketSessionKeyStoreSpy.ReadError.self) {
            try await sut.enable()
        }

        #expect(signer.calls.isEmpty)
        #expect(keyStore.generatedKeys == 0)
    }

    @Test("A device id that can't be read stops a renewal before the card tap, so the key is not revoked")
    func unreadableDeviceIdStopsRenewal() async throws {
        let signer = BatchesSignerSpy()
        let service = SessionKeyServiceSpy()
        let sut = try makeSUT(deviceIdProvider: PolymarketDeviceIdProviderStub(isReadable: false), signer: signer, service: service)

        await #expect(throws: PolymarketDeviceIdProviderStub.ReadError.self) {
            try await sut.renew()
        }

        #expect(signer.calls.isEmpty)
        #expect(service.revocations.isEmpty)
    }

    @Test("The card signature is reported before the key goes to the backend, so the caller can move on")
    func signatureIsReportedBeforeSubmission() async throws {
        let signer = BatchesSignerSpy()
        let service = SessionKeyServiceSpy()
        let sut = try makeSUT(signer: signer, service: service)
        let observed = OSAllocatedUnfairLock<[Int]>(initialState: [])

        _ = try await sut.enable(onSigned: {
            observed.withLock { $0 = [signer.calls.count, service.authorizations.count] }
        })

        #expect(observed.withLock { $0 } == [1, 0])
    }

    @Test("A device name longer than the backend allows is cut to 64 characters")
    func longDeviceNameIsCut() async throws {
        let service = SessionKeyServiceSpy()
        let sut = try makeSUT(deviceName: String(repeating: "a", count: 80), service: service)

        _ = try await sut.enable()

        let authorization = try #require(service.authorizations.first)

        #expect(authorization.deviceName.count == 64)
    }

    @Test("Missing owner credentials are obtained in the same card tap")
    func ownerCredentialsRideTheSameTap() async throws {
        let signer = BatchesSignerSpy()
        let ownerCredentials = OwnerCredentialsSpy(hasCredentials: false)
        let sut = try makeSUT(signer: signer, ownerCredentials: ownerCredentials)

        _ = try await sut.enable()

        let signed = try #require(signer.calls.first)

        #expect(signer.calls.count == 1)
        #expect(signed.ownerAuthTimestamp == String(Self.nowSeconds))
        #expect(ownerCredentials.obtainedCount == 1)
    }

    @Test("Owner credentials already on the device are not signed for again")
    func storedOwnerCredentialsAreReused() async throws {
        let signer = BatchesSignerSpy()
        let ownerCredentials = OwnerCredentialsSpy(hasCredentials: true)
        let sut = try makeSUT(signer: signer, ownerCredentials: ownerCredentials)

        _ = try await sut.enable()

        let signed = try #require(signer.calls.first)

        #expect(signed.ownerAuthTimestamp == nil)
        #expect(ownerCredentials.obtainedCount == 0)
    }

    @Test("Renewal signs the revocation and the follow-up authorization in one tap with consecutive nonces")
    func renewalSignsBothBatchesAtOnce() async throws {
        let signer = BatchesSignerSpy()
        let service = SessionKeyServiceSpy()
        let sut = try makeSUT(signer: signer, service: service)

        _ = try await sut.renew()

        let signed = try #require(signer.calls.first)

        #expect(signer.calls.count == 1)
        #expect(signed.batches.map(\.nonce) == ["7", "8"])
        #expect(signed.batches.map(\.deadline) == [String(Self.nowSeconds + 600), String(Self.nowSeconds + 1200)])
        #expect(service.revocations.map(\.sessionKeyAddress) == [Self.localAddress])
        #expect(service.authorizations.map(\.grant.sessionKeyAddress) == [Self.localAddress])
        #expect(service.events == [.revoke, .authorize])
    }

    @Test("Renewing without a key on the device is refused instead of creating one")
    func renewalNeedsTheHeldKey() async throws {
        let keyStore = PolymarketSessionKeyStoreSpy(heldAddress: nil)
        let signer = BatchesSignerSpy()
        let sut = try makeSUT(keyStore: keyStore, signer: signer)

        await #expect(throws: PolymarketSessionKeyManagerError.self) {
            try await sut.renew()
        }

        #expect(signer.calls.isEmpty)
        #expect(keyStore.generatedKeys == 0)
    }

    @Test("A renewal whose revocation did not go through neither sends the signed authorization nor keeps it for a resume")
    func failedRevocationStopsRenewal() async throws {
        let service = SessionKeyServiceSpy(afterRevocation: [.active])
        let sut = try makeSUT(service: service)

        await #expect(throws: PolymarketSessionKeyManagerError.self) {
            try await sut.renew()
        }

        #expect(service.authorizations.isEmpty)
        #expect(await sut.resumableInterruptedAuthorization() == nil)
    }

    @Test("A renewal cut off after its revocation went out is completed on the next start with the authorization signed for it")
    func interruptedRenewalIsResumedOnTheNextStart() async throws {
        let storage = PolymarketSecureStorageSpy()
        let signer = BatchesSignerSpy()
        let service = SessionKeyServiceSpy(unauthorizedValidityShift: -PolymarketSessionKeyFixtures.day, authorizeFailures: Self.unansweredAuthorization)
        let clock = PollingClockSpy()
        let interrupted = try makeSUT(signer: signer, service: service, clock: clock, secureStorage: storage)

        await #expect(throws: PolymarketSessionKeyError.self) {
            try await interrupted.renew()
        }

        let restarted = try makeSUT(signer: signer, service: service, clock: clock, secureStorage: storage, walletNonce: Self.authorizationNonce)

        #expect(await restarted.resumableInterruptedAuthorization() != nil)

        let sessionKey = try await restarted.resumeInterruptedAuthorization()

        #expect(sessionKey.status == .active)
        #expect(signer.calls.count == 1)
        #expect(service.revocations.count == 1)
        #expect(service.authorizations.count == Self.unansweredAuthorization.count + 1)
        #expect(Set(service.authorizations).count == 1)
        #expect(storage.items.isEmpty)
    }

    @Test("A renewal whose task is cancelled after the card signed keeps nothing for a resume and sends nothing")
    func cancelledRenewalKeepsNothing() async throws {
        let storage = PolymarketSecureStorageSpy()
        let signer = BatchesSignerSpy()
        let service = SessionKeyServiceSpy()
        let sut = try makeSUT(signer: signer, service: service, secureStorage: storage)
        let renewal = Task { try await sut.renew() }

        renewal.cancel()

        await #expect(throws: CancellationError.self) {
            try await renewal.value
        }

        #expect(signer.calls.count == 1)
        #expect(storage.items.isEmpty)
        #expect(service.revocations.isEmpty)
        #expect(service.authorizations.isEmpty)
    }

    @Test("Extending a paused key leaves it paused once the renewal settles, without another card tap")
    func renewalKeepsAPausedKeyPaused() async throws {
        let signer = BatchesSignerSpy()
        let service = SessionKeyServiceSpy(listings: [Self.localAddress: [.active]], disabled: [Self.localAddress])
        let sut = try makeSUT(signer: signer, service: service)

        let sessionKey = try await sut.renew()

        #expect(!sessionKey.isEnabled)
        #expect(service.events == [.revoke, .authorize, .setEnabled(false)])
        #expect(signer.calls.count == 1)
    }

    @Test("A paused key's renewal cut off after its revocation went out is completed on the next start and still ends paused")
    func interruptedRenewalOfAPausedKeyEndsPaused() async throws {
        let storage = PolymarketSecureStorageSpy()
        let service = SessionKeyServiceSpy(
            listings: [Self.localAddress: [.active]],
            disabled: [Self.localAddress],
            unauthorizedValidityShift: -PolymarketSessionKeyFixtures.day,
            authorizeFailures: Self.unansweredAuthorization
        )
        let clock = PollingClockSpy()
        let interrupted = try makeSUT(service: service, clock: clock, secureStorage: storage)

        await #expect(throws: PolymarketSessionKeyError.self) {
            try await interrupted.renew()
        }

        let restarted = try makeSUT(service: service, clock: clock, secureStorage: storage, walletNonce: Self.authorizationNonce)
        let sessionKey = try await restarted.resumeInterruptedAuthorization()

        #expect(!sessionKey.isEnabled)
        #expect(service.events == [.revoke, .authorize, .setEnabled(false)])
    }

    @Test("A paused key whose renewal went through is paused by a later resume when the backend first refuses the pause, even past the renewal's deadline")
    func refusedPauseOfARenewedKeyIsRetried() async throws {
        let storage = PolymarketSecureStorageSpy()
        let clock = PollingClockSpy()
        let service = SessionKeyServiceSpy(
            listings: [Self.localAddress: [.active]],
            disabled: [Self.localAddress],
            setEnabledFailures: [.refused(statusCode: 409, reason: .busy, detail: nil)]
        )
        let sut = try makeSUT(service: service, clock: clock, secureStorage: storage)

        let renewed = try await sut.renew()

        #expect(renewed.isEnabled)

        try await clock.wait(for: TimeInterval(PolymarketSessionKeyAuthorizationBatch.followUpDeadlineOffset))

        let restarted = try makeSUT(service: service, clock: clock, secureStorage: storage)
        let paused = try await restarted.resumeInterruptedAuthorization()

        #expect(!paused.isEnabled)
        #expect(service.events == [.revoke, .authorize, .setEnabled(false)])
        #expect(storage.items.isEmpty)
    }

    @Test("An authorization kept from a cut-off renewal is dropped instead of sent once its batch can no longer run")
    func expiredInterruptedAuthorizationIsDropped() async throws {
        let storage = PolymarketSecureStorageSpy()
        let service = SessionKeyServiceSpy(authorizeFailures: Self.unansweredAuthorization)
        let clock = PollingClockSpy()
        let interrupted = try makeSUT(service: service, clock: clock, secureStorage: storage)

        await #expect(throws: PolymarketSessionKeyError.self) {
            try await interrupted.renew()
        }

        try #require(!storage.items.isEmpty)
        try await clock.wait(for: TimeInterval(PolymarketSessionKeyAuthorizationBatch.followUpDeadlineOffset))

        let restarted = try makeSUT(service: service, clock: clock, secureStorage: storage)

        #expect(await restarted.resumableInterruptedAuthorization() == nil)
        await #expect(throws: PolymarketSessionKeyManagerError.self) {
            try await restarted.resumeInterruptedAuthorization()
        }

        #expect(service.authorizations.count == Self.unansweredAuthorization.count)
        #expect(storage.items.isEmpty)
    }

    @Test(
        "A card operation that spends the wallet's next nonce is refused while a renewal's signed authorization still holds it",
        arguments: [ManagerOperation.enable, .revoke, .renew]
    )
    func nonceSpendingOperationWaitsForAKeptAuthorization(_ operation: ManagerOperation) async throws {
        let storage = PolymarketSecureStorageSpy()
        let signer = BatchesSignerSpy()
        let sut = try makeSUT(signer: signer, service: SessionKeyServiceSpy(authorizeFailures: Self.unansweredAuthorization), secureStorage: storage)

        await #expect(throws: PolymarketSessionKeyError.self) {
            try await sut.renew()
        }

        let refusal = await #expect(throws: PolymarketSessionKeyManagerError.self) {
            try await operation.run(on: sut)
        }

        #expect(refusal?.isOperationInProgress == true)
        #expect(signer.calls.count == 1)
        #expect(!storage.items.isEmpty)
    }

    @Test("A paused key's renewal that went through stops holding the wallet's next nonce while the pause waits for a retry")
    func renewedKeyKeptPausedDoesNotHoldTheNextNonce() async throws {
        let service = SessionKeyServiceSpy(
            listings: [Self.localAddress: [.active]],
            disabled: [Self.localAddress],
            setEnabledFailures: [.refused(statusCode: 409, reason: .busy, detail: nil)]
        )
        let sut = try makeSUT(service: service)

        _ = try await sut.renew()
        _ = try await sut.revoke(sessionKeyAddress: Self.previousAddress)

        #expect(service.revocations.map(\.sessionKeyAddress) == [Self.localAddress, Self.previousAddress])
        #expect(await sut.keptPausedKeyAddress() == Self.localAddress)
    }

    @Test("Resuming a key kept paused after its renewal drops the kept pause, so the key is not paused again")
    func resumingAKeptPausedKeyDropsThePause() async throws {
        let storage = PolymarketSecureStorageSpy()
        let service = SessionKeyServiceSpy(
            listings: [Self.localAddress: [.active]],
            disabled: [Self.localAddress],
            setEnabledFailures: [.refused(statusCode: 409, reason: .busy, detail: nil)]
        )
        let sut = try makeSUT(service: service, secureStorage: storage)

        _ = try await sut.renew()
        _ = try await sut.setEnabled(true, sessionKeyAddress: Self.localAddress)

        #expect(await sut.keptPausedKeyAddress() == nil)
        #expect(storage.items.isEmpty)
    }

    @Test(
        "A cut-off renewal is kept for its resume as a renewal and a cut-off repair as an activation, though both authorize the same key",
        arguments: zip([ManagerOperation.renew, .repair], [PolymarketInterruptedAuthorization.Purpose.renewal, .activation])
    )
    func interruptedReauthorizationKeepsItsPurpose(_ operation: ManagerOperation, _ purpose: PolymarketInterruptedAuthorization.Purpose) async throws {
        let storage = PolymarketSecureStorageSpy()
        let clock = PollingClockSpy()
        let service = SessionKeyServiceSpy(authorizeFailures: Self.unansweredAuthorization)
        let interrupted = try makeSUT(service: service, clock: clock, secureStorage: storage)

        await #expect(throws: PolymarketSessionKeyError.self) {
            try await operation.run(on: interrupted)
        }

        let restarted = try makeSUT(service: service, clock: clock, secureStorage: storage)

        #expect(await restarted.resumableInterruptedAuthorization()?.purpose == purpose)
    }

    @Test("A revocation the relayer runs after five minutes, still within its deadline, is followed by the authorization")
    func lateRevocationIsFollowedByTheAuthorization() async throws {
        let revoking = [PolymarketSessionKey.Status?](repeating: .revoking, count: 120)
        let service = SessionKeyServiceSpy(afterRevocation: revoking + [.revoked])
        let sut = try makeSUT(service: service)

        _ = try await sut.renew()

        #expect(service.authorizations.map(\.grant.sessionKeyAddress) == [Self.localAddress])
    }

    @Test("A revoking key the backend stops listing counts as revoked and the authorization follows")
    func vanishedRevokingKeyCountsAsRevoked() async throws {
        let service = SessionKeyServiceSpy(afterRevocation: [nil])
        let sut = try makeSUT(service: service)

        _ = try await sut.renew()

        #expect(service.authorizations.map(\.grant.sessionKeyAddress) == [Self.localAddress])
    }

    @Test("Replacing a key the exchange still lists revokes it first")
    func replaceWithRevocation() async throws {
        let service = SessionKeyServiceSpy()
        let sut = try makeSUT(service: service)

        _ = try await sut.replace(previousSessionKeyAddress: Self.previousAddress, revokesPrevious: true)

        #expect(service.revocations.map(\.sessionKeyAddress) == [Self.previousAddress])
        #expect(service.authorizations.map(\.grant.sessionKeyAddress) == [Self.localAddress])
        #expect(service.authorizations.first?.replacesSessionKeyAddress == nil)
    }

    @Test("Replacing a key the exchange already dropped names it instead of revoking it")
    func replaceWithoutRevocation() async throws {
        let service = SessionKeyServiceSpy()
        let sut = try makeSUT(service: service)

        _ = try await sut.replace(previousSessionKeyAddress: Self.previousAddress, revokesPrevious: false)

        let authorization = try #require(service.authorizations.first)

        #expect(service.revocations.isEmpty)
        #expect(authorization.replacesSessionKeyAddress == Self.previousAddress)
    }

    @Test("Replacing the key of an earlier install creates this device's key when it has none")
    func replaceCreatesAMissingKey() async throws {
        let service = SessionKeyServiceSpy()
        let sut = try makeSUT(keyStore: PolymarketSessionKeyStoreSpy(heldAddress: nil), service: service)

        _ = try await sut.replace(previousSessionKeyAddress: Self.previousAddress, revokesPrevious: false)

        let authorization = try #require(service.authorizations.first)

        #expect(authorization.grant.sessionKeyAddress == PolymarketSessionKeyStoreSpy.generatedAddress)
        #expect(authorization.replacesSessionKeyAddress == Self.previousAddress)
    }

    @Test("An unanswered request is sent again unchanged instead of being signed again")
    func unansweredRequestIsResent() async throws {
        let signer = BatchesSignerSpy()
        let service = SessionKeyServiceSpy(authorizeFailures: [.gatewayFailure, .gatewayFailure])
        let sut = try makeSUT(signer: signer, service: service)

        _ = try await sut.enable()

        #expect(signer.calls.count == 1)
        #expect(service.authorizations.count == 3)
        #expect(Set(service.authorizations).count == 1)
    }

    @Test("Resending an unanswered request stops after three more attempts")
    func resendIsBounded() async throws {
        let service = SessionKeyServiceSpy(authorizeFailures: Array(repeating: .gatewayFailure, count: 10))
        let sut = try makeSUT(service: service)

        await #expect(throws: PolymarketSessionKeyError.self) {
            try await sut.enable()
        }

        #expect(service.authorizations.count == 4)
    }

    @Test("A throttled or timed out request is sent again unchanged", arguments: [408, 429])
    func throttledRequestIsResent(_ statusCode: Int) async throws {
        let throttled = SessionKeyServiceSpy.Failure(
            error: PolymarketSessionKeyError(apiError: .http(statusCode: statusCode, problemDetail: nil)),
            isTaken: false
        )
        let service = SessionKeyServiceSpy(authorizeFailures: [throttled, throttled])
        let sut = try makeSUT(service: service)

        _ = try await sut.enable()

        #expect(service.authorizations.count == 3)
        #expect(Set(service.authorizations).count == 1)
    }

    @Test("A request the backend refuses with a client error is not sent again", arguments: [400, 403, 409, 422])
    func clientRefusalIsNotResent(_ statusCode: Int) async throws {
        let refusal = SessionKeyServiceSpy.Failure(
            error: PolymarketSessionKeyError(apiError: .http(statusCode: statusCode, problemDetail: nil)),
            isTaken: false
        )
        let service = SessionKeyServiceSpy(authorizeFailures: [refusal])
        let sut = try makeSUT(service: service)

        await #expect(throws: PolymarketSessionKeyError.self) {
            try await sut.enable()
        }

        #expect(service.authorizations.count == 1)
    }

    @Test("A refused request is not sent again")
    func refusalIsNotResent() async throws {
        let service = SessionKeyServiceSpy(authorizeFailures: [.busy])
        let sut = try makeSUT(service: service)

        await #expect(throws: PolymarketSessionKeyError.self) {
            try await sut.enable()
        }

        #expect(service.authorizations.count == 1)
    }

    @Test("A renewal goes on when the resent revocation is refused because the backend took the first copy")
    func refusedResendOfATakenRevocationContinues() async throws {
        let service = SessionKeyServiceSpy(afterRevocation: [.revoking, .revoked], revokeFailures: [.lostAnswer, .nonceAlreadyUsed])
        let sut = try makeSUT(service: service)

        _ = try await sut.renew()

        #expect(service.revocations.count == 2)
        #expect(service.authorizations.map(\.grant.sessionKeyAddress) == [Self.localAddress])
    }

    @Test("An activation waits for the key when the resent authorization is refused because the backend took the first copy")
    func refusedResendOfATakenAuthorizationContinues() async throws {
        let service = SessionKeyServiceSpy(afterAuthorization: [.pending, .active], authorizeFailures: [.lostAnswer, .nonceAlreadyUsed])
        let sut = try makeSUT(service: service)

        let sessionKey = try await sut.enable()

        #expect(sessionKey.status == .active)
        #expect(service.authorizations.count == 2)
    }

    @Test("An activation keeps checking the exchange after it first answered that the key is not ready yet")
    func activationOutwaitsARememberedNotReadyAnswer() async throws {
        let router = RouterSpy(notReadyChecks: 2)
        let sut = try makeSUT(router: router)

        _ = try await sut.enable()

        #expect(await router.readyRoutes == 1)
    }

    @Test("A refused resend is not taken for success when the listed key still has the validity of an earlier authorization")
    func refusedResendOfAnOlderAuthorizationIsReported() async throws {
        let service = SessionKeyServiceSpy(
            listedValidityShift: -PolymarketSessionKeyFixtures.day,
            afterAuthorization: [.active],
            authorizeFailures: [.lostAnswer, .nonceAlreadyUsed]
        )
        let sut = try makeSUT(service: service)

        await #expect(throws: PolymarketSessionKeyError.self) {
            try await sut.enable()
        }
    }

    @Test("A resent revocation refused while the key is still active is reported and the authorization stays unsent")
    func refusedResendOfAnUntakenRevocationStopsRenewal() async throws {
        let service = SessionKeyServiceSpy(listings: [Self.localAddress: [.active]], revokeFailures: [.gatewayFailure, .busy])
        let sut = try makeSUT(service: service)

        await #expect(throws: PolymarketSessionKeyError.self) {
            try await sut.renew()
        }

        #expect(service.revocations.count == 2)
        #expect(service.authorizations.isEmpty)
    }

    @Test("Waiting for a key the relayer never settles lasts until its batch can no longer run")
    func waitingLastsUntilTheDeadline() async throws {
        let service = SessionKeyServiceSpy(afterAuthorization: [.pending])
        let clock = PollingClockSpy()
        let sut = try makeSUT(service: service, clock: clock)

        await #expect(throws: PolymarketSessionKeyManagerError.self) {
            try await sut.enable()
        }

        #expect(clock.now > Self.now.addingTimeInterval(600))
    }

    @Test("A key the backend briefly leaves out is waited for instead of being judged by an earlier revoked record of the same address")
    func earlierRecordDoesNotStandInForAMissingOne() async throws {
        let service = SessionKeyServiceSpy(
            earlierRecords: [Self.key(address: Self.localAddress, status: .revoked, validityShift: -PolymarketSessionKeyFixtures.day)],
            afterAuthorization: [nil, .active]
        )
        let sut = try makeSUT(service: service)

        let sessionKey = try await sut.enable()

        #expect(sessionKey.status == .active)
    }

    @Test("A pending key the backend leaves out of a few reads is still waited for")
    func briefGapKeepsWaiting() async throws {
        let gap = [PolymarketSessionKey.Status?](repeating: nil, count: PolymarketSessionKey.settlingMissTolerance)
        let service = SessionKeyServiceSpy(afterAuthorization: gap + [.active])
        let sut = try makeSUT(service: service)

        let sessionKey = try await sut.enable()

        #expect(sessionKey.status == .active)
    }

    @Test("A throttled or timed out read while the key settles is waited out instead of failing the activation after the card tap", arguments: [408, 429])
    func throttledSettlementReadKeepsWaiting(_ statusCode: Int) async throws {
        let service = SessionKeyServiceSpy(
            readFailuresAfterAuthorization: [PolymarketSessionKeyError(apiError: .http(statusCode: statusCode, problemDetail: nil))]
        )
        let sut = try makeSUT(service: service)

        let sessionKey = try await sut.enable()

        #expect(sessionKey.status == .active)
        #expect(service.sessionKeyReads >= 2)
    }

    @Test("A pending key the backend stops listing fails the activation without waiting out its deadline")
    func vanishedPendingKeyFailsTheActivation() async throws {
        let service = SessionKeyServiceSpy(afterAuthorization: [nil])
        let sut = try makeSUT(service: service)

        await #expect(throws: PolymarketSessionKeyManagerError.self) {
            try await sut.enable()
        }

        #expect(service.sessionKeyReads == PolymarketSessionKey.settlingMissTolerance + 1)
    }

    @Test("An authorization the relayer failed is reported")
    func failedAuthorizationIsReported() async throws {
        let sut = try makeSUT(service: SessionKeyServiceSpy(afterAuthorization: [.failed]))

        await #expect(throws: PolymarketSessionKeyManagerError.self) {
            try await sut.enable()
        }
    }

    @Test("Revoking returns as soon as the backend accepts the revocation")
    func revokeDoesNotWait() async throws {
        let service = SessionKeyServiceSpy()
        let router = RouterSpy()
        let sut = try makeSUT(service: service, router: router)

        let revoking = try await sut.revoke(sessionKeyAddress: Self.previousAddress)

        #expect(revoking.status == .revoking)
        #expect(service.sessionKeyReads == 0)
        #expect(await router.invalidations == 1)
    }

    @Test("A key stays revocable while the wallet is deployed but not ready to trade")
    func revokeAcceptsADeployedWallet() async throws {
        let service = SessionKeyServiceSpy()
        let sut = try makeSUT(walletStatus: .approvalsFailed, service: service)

        _ = try await sut.revoke(sessionKeyAddress: Self.previousAddress)

        #expect(service.revocations.count == 1)
    }

    @Test("A wallet that is not ready to trade cannot enable fast trading")
    func enableNeedsAReadyWallet() async throws {
        let signer = BatchesSignerSpy()
        let sut = try makeSUT(walletStatus: .approvalsFailed, signer: signer)

        await #expect(throws: (any Error).self) {
            try await sut.enable()
        }

        #expect(signer.calls.isEmpty)
    }

    @Test("An operation started while another one is in flight is refused, and the next one goes through once it ends")
    func overlappingOperationIsRefused() async throws {
        let release = TestGate()
        let signer = BatchesSignerSpy(release: release)
        let service = SessionKeyServiceSpy()
        let sut = try makeSUT(signer: signer, service: service)

        let enabling = Task { try await sut.enable() }
        await signer.reached.wait()

        let overlapping = await #expect(throws: PolymarketSessionKeyManagerError.self) {
            try await sut.revoke(sessionKeyAddress: Self.previousAddress)
        }

        release.open()
        _ = try await enabling.value
        _ = try await sut.revoke(sessionKeyAddress: Self.previousAddress)

        #expect(overlapping?.isOperationInProgress == true)
        #expect(service.revocations.count == 1)
    }

    @Test("An operation that failed leaves the manager free for the next one")
    func failedOperationReleasesTheManager() async throws {
        let service = SessionKeyServiceSpy()
        let sut = try makeSUT(keyStore: PolymarketSessionKeyStoreSpy(heldAddress: nil), service: service)

        await #expect(throws: PolymarketSessionKeyManagerError.self) {
            try await sut.renew()
        }

        _ = try await sut.enable()

        #expect(service.authorizations.count == 1)
    }

    @Test("A renewal cut off before the backend took its revocation sends the kept revocation first, then the authorization, without another card tap")
    func keptRevocationIsSentBeforeItsAuthorization() async throws {
        let storage = PolymarketSecureStorageSpy()
        let clock = PollingClockSpy()
        let signer = BatchesSignerSpy()
        let service = SessionKeyServiceSpy(listings: [Self.localAddress: [.active]], unauthorizedValidityShift: -PolymarketSessionKeyFixtures.day, revokeFailures: Self.unansweredRevocation)
        let interrupted = try makeSUT(signer: signer, service: service, clock: clock, secureStorage: storage)

        await #expect(throws: PolymarketSessionKeyError.self) {
            try await interrupted.renew()
        }

        let restarted = try makeSUT(signer: signer, service: service, clock: clock, secureStorage: storage)
        let sessionKey = try await restarted.resumeInterruptedAuthorization()

        #expect(sessionKey.status == .active)
        #expect(signer.calls.count == 1)
        #expect(service.events == [.revoke, .authorize])
        #expect(Set(service.revocations).count == 1)
        #expect(storage.items.isEmpty)
    }

    @Test(
        "A kept authorization is dropped unsent once its revocation can no longer run or another operation took its nonce",
        arguments: zip([TimeInterval(PolymarketSessionKeyAuthorizationBatch.deadlineOffset), 0], [Self.revocationNonce, "9"])
    )
    func keptAuthorizationIsDroppedWhenItCanNoLongerFollowItsRevocation(_ elapsed: TimeInterval, _ walletNonce: String) async throws {
        let storage = PolymarketSecureStorageSpy()
        let clock = PollingClockSpy()
        let service = SessionKeyServiceSpy(listings: [Self.localAddress: [.active]], unauthorizedValidityShift: -PolymarketSessionKeyFixtures.day, revokeFailures: Self.unansweredRevocation)
        let interrupted = try makeSUT(service: service, clock: clock, secureStorage: storage)

        await #expect(throws: PolymarketSessionKeyError.self) {
            try await interrupted.renew()
        }

        try await clock.wait(for: elapsed)

        let restarted = try makeSUT(service: service, clock: clock, secureStorage: storage, walletNonce: walletNonce)

        let failure = await #expect(throws: PolymarketSessionKeyManagerError.self) {
            try await restarted.resumeInterruptedAuthorization()
        }

        #expect(failure?.isNoInterruptedAuthorization == true)
        #expect(service.events.isEmpty)
        #expect(service.authorizations.isEmpty)
        #expect(storage.items.isEmpty)
    }

    @Test(
        "A resent authorization the backend refuses as busy stays kept for a later resume, a final refusal drops it",
        arguments: zip([PolymarketSessionKeyError.Reason.busy, .nonceAlreadyUsed], [true, false])
    )
    func busyRefusalKeepsTheInterruptedAuthorization(_ reason: PolymarketSessionKeyError.Reason, _ isKept: Bool) async throws {
        let storage = PolymarketSecureStorageSpy()
        let clock = PollingClockSpy()
        let refusal = SessionKeyServiceSpy.Failure(error: .refused(statusCode: 409, reason: reason, detail: nil), isTaken: false)
        let service = SessionKeyServiceSpy(unauthorizedValidityShift: -PolymarketSessionKeyFixtures.day, authorizeFailures: Self.unansweredAuthorization + [refusal])
        let interrupted = try makeSUT(service: service, clock: clock, secureStorage: storage)

        await #expect(throws: PolymarketSessionKeyError.self) {
            try await interrupted.renew()
        }

        let restarted = try makeSUT(service: service, clock: clock, secureStorage: storage, walletNonce: Self.authorizationNonce)

        await #expect(throws: PolymarketSessionKeyError.self) {
            try await restarted.resumeInterruptedAuthorization()
        }

        #expect((await restarted.resumableInterruptedAuthorization() != nil) == isKept)
    }

    @Test("A kept authorization whose revocation nonce another operation spent is dropped and reported instead of finishing as a replacement")
    func keptAuthorizationIsDroppedWhenAnotherOperationSpentTheRevocationNonce() async throws {
        let storage = PolymarketSecureStorageSpy()
        let clock = PollingClockSpy()
        let interrupted = try makeSUT(
            service: SessionKeyServiceSpy(listings: [Self.previousAddress: [.active]], revokeFailures: Self.unansweredRevocation),
            clock: clock,
            secureStorage: storage
        )

        await #expect(throws: PolymarketSessionKeyError.self) {
            try await interrupted.replace(previousSessionKeyAddress: Self.previousAddress, revokesPrevious: true)
        }

        let service = SessionKeyServiceSpy(listings: [Self.previousAddress: [.active]])
        let restarted = try makeSUT(service: service, clock: clock, secureStorage: storage, walletNonce: Self.authorizationNonce)

        let failure = await #expect(throws: PolymarketSessionKeyManagerError.self) {
            try await restarted.resumeInterruptedAuthorization()
        }

        #expect(failure?.isNonceSpentElsewhere == true)
        #expect(service.authorizations.isEmpty)
        #expect(storage.items.isEmpty)
    }

    @Test("A pause kept for a renewed key outlives another authorization of the key settling, so the key stays off one-tap orders")
    func keptPauseOutlivesAnotherAuthorization() async throws {
        let storage = PolymarketSecureStorageSpy()
        let service = SessionKeyServiceSpy(
            listings: [Self.localAddress: [.active]],
            disabled: [Self.localAddress],
            setEnabledFailures: [.refused(statusCode: 409, reason: .busy, detail: nil)]
        )
        let sut = try makeSUT(service: service, secureStorage: storage)

        _ = try await sut.renew()

        try #require(await sut.keptPausedKeyAddress() == Self.localAddress)

        _ = try await sut.enable()

        #expect(await sut.keptPausedKeyAddress() == Self.localAddress)
    }

    @Test("A kept authorization the relayer failed is reported as a failed authorization and dropped")
    func failedKeptAuthorizationIsReported() async throws {
        let storage = PolymarketSecureStorageSpy()
        let clock = PollingClockSpy()
        let interrupted = try makeSUT(
            service: SessionKeyServiceSpy(authorizeFailures: Self.unansweredAuthorization),
            clock: clock,
            secureStorage: storage
        )

        await #expect(throws: PolymarketSessionKeyError.self) {
            try await interrupted.renew()
        }

        let failed = SessionKeyServiceSpy(earlierRecords: [Self.key(address: Self.localAddress, status: .failed)])
        let restarted = try makeSUT(service: failed, clock: clock, secureStorage: storage, walletNonce: Self.authorizationNonce)

        let failure = await #expect(throws: PolymarketSessionKeyManagerError.self) {
            try await restarted.resumeInterruptedAuthorization()
        }

        #expect(failure?.isAuthorizationFailed == true)
        #expect(failed.authorizations.isEmpty)
        #expect(storage.items.isEmpty)
    }

    @Test("A renewal whose signed batches can't be kept for a resume sends nothing")
    func unkeptRenewalSendsNothing() async throws {
        let storage = PolymarketSecureStorageSpy()
        storage.writeError = CommonPolymarketSessionKeyStore.KeyError.keyMissing
        let service = SessionKeyServiceSpy()
        let sut = try makeSUT(service: service, secureStorage: storage)

        await #expect(throws: CommonPolymarketSessionKeyStore.KeyError.self) {
            try await sut.renew()
        }

        #expect(service.revocations.isEmpty)
        #expect(service.authorizations.isEmpty)
    }

    @Test("A kept authorization stays kept when reading the keys fails during its resend")
    func keptAuthorizationSurvivesAFailedRead() async throws {
        let storage = PolymarketSecureStorageSpy()
        let clock = PollingClockSpy()
        let interrupted = try makeSUT(
            service: SessionKeyServiceSpy(authorizeFailures: Self.unansweredAuthorization),
            clock: clock,
            secureStorage: storage
        )

        await #expect(throws: PolymarketSessionKeyError.self) {
            try await interrupted.renew()
        }

        let unreadable = SessionKeyServiceSpy(readFailures: [PolymarketSessionKeyError(apiError: .http(statusCode: 401, problemDetail: nil))])
        let restarted = try makeSUT(service: unreadable, clock: clock, secureStorage: storage)

        await #expect(throws: PolymarketSessionKeyError.self) {
            try await restarted.resumeInterruptedAuthorization()
        }

        #expect(unreadable.authorizations.isEmpty)
        #expect(await restarted.resumableInterruptedAuthorization() != nil)
    }

    @Test(
        "A kept authorization whose revocation the backend still shows revoking at the next wallet nonce is sent only once the key settles revoked",
        arguments: zip([PolymarketSessionKey.Status?.some(.revoked), .some(.active), nil], [true, false, false])
    )
    func revocationAtTheNextNonceMustSettleRevoked(_ settled: PolymarketSessionKey.Status?, _ isSent: Bool) async throws {
        let storage = PolymarketSecureStorageSpy()
        let clock = PollingClockSpy()
        let interrupted = try makeSUT(
            service: SessionKeyServiceSpy(authorizeFailures: Self.unansweredAuthorization),
            clock: clock,
            secureStorage: storage
        )

        await #expect(throws: PolymarketSessionKeyError.self) {
            try await interrupted.renew()
        }

        let service = SessionKeyServiceSpy(listings: [Self.localAddress: [.revoking, settled]], unauthorizedValidityShift: -PolymarketSessionKeyFixtures.day)
        let restarted = try makeSUT(service: service, clock: clock, secureStorage: storage, walletNonce: Self.authorizationNonce)

        if isSent {
            #expect(try await restarted.resumeInterruptedAuthorization().status == .active)
        } else {
            let failure = await #expect(throws: PolymarketSessionKeyManagerError.self) {
                try await restarted.resumeInterruptedAuthorization()
            }

            #expect(failure?.isRevocationFailed == true)
        }

        #expect(service.authorizations.count == (isSent ? 1 : 0))
    }

    @Test(
        "A kept renewal of a paused key stays kept with its pause when the read after its resend fails with a client error or an unreadable answer",
        arguments: [
            PolymarketSessionKeyError.refused(statusCode: 403, reason: .unknown(nil), detail: nil),
            .other(.decoding(field: "status", value: "SUSPENDED?")),
        ]
    )
    func keptPausedRenewalSurvivesAFailedReadAfterItsResend(_ readFailure: PolymarketSessionKeyError) async throws {
        let storage = PolymarketSecureStorageSpy()
        let clock = PollingClockSpy()
        let interrupted = try makeSUT(
            service: SessionKeyServiceSpy(
                listings: [Self.localAddress: [.active]],
                disabled: [Self.localAddress],
                authorizeFailures: Self.unansweredAuthorization
            ),
            clock: clock,
            secureStorage: storage
        )

        await #expect(throws: PolymarketSessionKeyError.self) {
            try await interrupted.renew()
        }

        let service = SessionKeyServiceSpy(listings: [Self.localAddress: [.revoked]], unauthorizedValidityShift: -PolymarketSessionKeyFixtures.day, readFailuresAfterAuthorization: [readFailure])
        let restarted = try makeSUT(service: service, clock: clock, secureStorage: storage, walletNonce: Self.authorizationNonce)

        await #expect(throws: PolymarketSessionKeyError.self) {
            try await restarted.resumeInterruptedAuthorization()
        }

        #expect(service.authorizations.count == 1)
        #expect(!storage.items.isEmpty)
        #expect(await restarted.keptPausedKeyAddress() == Self.localAddress)
    }

    @Test("A kept authorization is not offered for a resend while another operation holds the wallet")
    func keptAuthorizationWaitsForAFreeWallet() async throws {
        let gate = PolymarketWalletOperationGate()
        let sut = try makeSUT(operationGate: gate, service: SessionKeyServiceSpy(authorizeFailures: Self.unansweredAuthorization))

        await #expect(throws: PolymarketSessionKeyError.self) {
            try await sut.renew()
        }

        let entered = TestGate()
        let release = TestGate()
        let holding = Task {
            try await gate.exclusively(Self.userWalletId, orThrow: CancellationError()) {
                entered.open()
                await release.wait()
            }
        }

        await entered.wait()

        #expect(await sut.resumableInterruptedAuthorization() == nil)

        release.open()
        try await holding.value

        #expect(await sut.resumableInterruptedAuthorization() != nil)
    }
}

// MARK: - Arguments

extension PolymarketSessionKeyManagerTests {
    enum ManagerOperation {
        case enable
        case revoke
        case renew
        case repair

        func run(on manager: PolymarketSessionKeyManaging) async throws {
            switch self {
            case .enable:
                _ = try await manager.enable()
            case .revoke:
                _ = try await manager.revoke(sessionKeyAddress: PolymarketSessionKeyManagerTests.previousAddress)
            case .renew:
                _ = try await manager.renew()
            case .repair:
                _ = try await manager.repair()
            }
        }
    }
}

// MARK: - Helpers

private extension PolymarketSessionKeyManagerTests {
    static let now = Date(timeIntervalSince1970: 1_789_430_400)
    static let nowSeconds = Int(now.timeIntervalSince1970)
    static let localAddress = "0x5e55000000000000000000000000000000000001"
    static let previousAddress = "0x5e55000000000000000000000000000000000002"
    static let deviceId = PolymarketSessionKeyFixtures.deviceId
    static let deviceName = "iPhone 16 Pro"
    static let userWalletId = UserWalletId(value: Data(repeating: 0x03, count: 32))
    static let unansweredAuthorization = [SessionKeyServiceSpy.Failure](repeating: .gatewayFailure, count: 4)
    static let unansweredRevocation = unansweredAuthorization
    static let revocationNonce = PolymarketRelayerServiceStub.nonce
    static let authorizationNonce = "8"

    func makeSUT(
        operationGate: PolymarketWalletOperationGate = PolymarketWalletOperationGate(),
        keyStore: PolymarketSessionKeyStoreSpy = PolymarketSessionKeyStoreSpy(heldAddress: Self.localAddress),
        deviceIdProvider: PolymarketDeviceIdProviderStub = PolymarketDeviceIdProviderStub(),
        deviceName: String = Self.deviceName,
        walletStatus: PolymarketDepositWalletStatus = .readyToTrade,
        signer: BatchesSignerSpy = BatchesSignerSpy(),
        service: SessionKeyServiceSpy = SessionKeyServiceSpy(),
        ownerCredentials: OwnerCredentialsSpy = OwnerCredentialsSpy(hasCredentials: true),
        router: RouterSpy = RouterSpy(),
        clock: PollingClockSpy = PollingClockSpy(),
        secureStorage: PolymarketSecureStorageSpy = PolymarketSecureStorageSpy(),
        walletNonce: String = Self.revocationNonce
    ) throws -> CommonPolymarketSessionKeyManager {
        let ownerAddress = PolymarketOwnerAddressProviderStub.ownerAddress
        let depositWalletAddress = try PolymarketDepositWalletDeriver.derive(ownerAddress: ownerAddress)

        return CommonPolymarketSessionKeyManager(
            userWalletId: Self.userWalletId,
            keyStore: keyStore,
            deviceIdProvider: deviceIdProvider,
            deviceName: deviceName,
            depositWalletResolver: PolymarketDepositWalletResolver(
                walletService: PolymarketDepositWalletServiceStub(status: walletStatus, depositWalletAddress: depositWalletAddress),
                ownerAddressProvider: PolymarketOwnerAddressProviderStub(derived: ownerAddress)
            ),
            relayerService: PolymarketRelayerServiceStub(result: .success(walletNonce)),
            signer: signer,
            sessionKeyService: service,
            ownerCredentials: ownerCredentials,
            signingRouter: router,
            interruptedAuthorizations: CommonPolymarketInterruptedAuthorizationStore(secureStorage: secureStorage),
            serverClock: PolymarketServerClock(deviceNow: { clock.now }),
            operationGate: operationGate,
            pollDelayProvider: clock
        )
    }

    static func key(
        address: String,
        status: PolymarketSessionKey.Status,
        isEnabled: Bool = true,
        validityShift: TimeInterval = 0
    ) -> PolymarketSessionKey {
        PolymarketSessionKey(
            address: address,
            deviceId: deviceId,
            deviceName: deviceName,
            isEnabled: isEnabled,
            status: status,
            scopes: ["CLOB"],
            validUntil: now.addingTimeInterval(PolymarketSessionKeyFixtures.validity + validityShift),
            renewAfter: nil,
            authorizedAt: now,
            createdAt: now
        )
    }
}

private extension PolymarketSessionKeyManaging {
    func enable() async throws -> PolymarketSessionKey {
        try await enable(onSigned: {})
    }

    func renew() async throws -> PolymarketSessionKey {
        try await renew(onSigned: {})
    }

    func repair() async throws -> PolymarketSessionKey {
        try await repair(onSigned: {})
    }

    func replace(previousSessionKeyAddress: String, revokesPrevious: Bool) async throws -> PolymarketSessionKey {
        try await replace(previousSessionKeyAddress: previousSessionKeyAddress, revokesPrevious: revokesPrevious, onSigned: {})
    }
}

private extension PolymarketSessionKeyManagerError {
    var isOperationInProgress: Bool {
        guard case .operationInProgress = self else {
            return false
        }

        return true
    }

    var isNoInterruptedAuthorization: Bool {
        guard case .noInterruptedAuthorization = self else {
            return false
        }

        return true
    }

    var isAuthorizationFailed: Bool {
        guard case .authorizationFailed = self else {
            return false
        }

        return true
    }

    var isNonceSpentElsewhere: Bool {
        guard case .nonceSpentElsewhere = self else {
            return false
        }

        return true
    }

    var isRevocationFailed: Bool {
        guard case .revocationFailed = self else {
            return false
        }

        return true
    }
}

// MARK: - Stubs

private final class BatchesSignerSpy: PolymarketBatchesSigning, Sendable {
    struct Call {
        let batches: [PolymarketRelayedBatch.Unsigned]
        let ownerAuthTimestamp: String?
    }

    let reached = TestGate()

    private let release: TestGate?
    private let recorded = OSAllocatedUnfairLock<[Call]>(initialState: [])

    init(release: TestGate? = nil) {
        self.release = release
    }

    var calls: [Call] {
        recorded.withLock { $0 }
    }

    func sign(
        _ batches: [PolymarketRelayedBatch.Unsigned],
        ownerAuthTimestamp: String?,
        as ownerAddress: String
    ) async throws(PolymarketSigningError) -> PolymarketSignedBatches {
        recorded.withLock { $0.append(Call(batches: batches, ownerAuthTimestamp: ownerAuthTimestamp)) }
        reached.open()
        await release?.wait()

        return PolymarketSignedBatches(
            batches: batches.map { $0.signed(by: ownerAddress, signature: "0xcard") },
            ownerAuthHeaders: ownerAuthTimestamp.map { timestamp in
                PolymarketCLOBAuthHeaders(ownerAddress: ownerAddress, signature: "0xauth", timestamp: timestamp, nonce: PolymarketClobAuth.nonce)
            }
        )
    }
}

private final class SessionKeyServiceSpy: PolymarketSessionKeyService, Sendable {
    enum Event: Equatable {
        case authorize
        case revoke
        case setEnabled(Bool)
    }

    struct Failure {
        let error: PolymarketSessionKeyError
        let isTaken: Bool

        static let gatewayFailure = Failure(error: .other(.http(statusCode: 502, problemDetail: nil)), isTaken: false)
        static let lostAnswer = Failure(error: .other(.connection(underlying: URLError(.timedOut))), isTaken: true)
        static let busy = Failure(error: .refused(statusCode: 409, reason: .busy, detail: nil), isTaken: false)
        static let nonceAlreadyUsed = Failure(error: .refused(statusCode: 409, reason: .nonceAlreadyUsed, detail: nil), isTaken: false)
    }

    private let state: OSAllocatedUnfairLock<State>
    private let listedValidityShift: TimeInterval
    private let unauthorizedValidityShift: TimeInterval
    private let earlierRecords: [PolymarketSessionKey]

    init(
        listings: [String: [PolymarketSessionKey.Status?]] = [:],
        disabled: Set<String> = [],
        earlierRecords: [PolymarketSessionKey] = [],
        listedValidityShift: TimeInterval = 0,
        unauthorizedValidityShift: TimeInterval = 0,
        afterAuthorization: [PolymarketSessionKey.Status?] = [.active],
        afterRevocation: [PolymarketSessionKey.Status?] = [.revoked],
        authorizeFailures: [Failure] = [],
        revokeFailures: [Failure] = [],
        setEnabledFailures: [PolymarketSessionKeyError] = [],
        readFailures: [PolymarketSessionKeyError] = [],
        readFailuresAfterAuthorization: [PolymarketSessionKeyError] = []
    ) {
        self.listedValidityShift = listedValidityShift
        self.unauthorizedValidityShift = unauthorizedValidityShift
        self.earlierRecords = earlierRecords
        state = OSAllocatedUnfairLock(initialState: State(
            listings: listings,
            disabled: disabled,
            afterAuthorization: afterAuthorization,
            afterRevocation: afterRevocation,
            authorizeFailures: authorizeFailures,
            revokeFailures: revokeFailures,
            setEnabledFailures: setEnabledFailures,
            readFailures: readFailures,
            readFailuresAfterAuthorization: readFailuresAfterAuthorization
        ))
    }

    var authorizations: [PolymarketSessionKeyAuthorization] {
        state.withLock { $0.authorizations }
    }

    var revocations: [PolymarketSessionKeyRevocation] {
        state.withLock { $0.revocations }
    }

    var events: [Event] {
        state.withLock { $0.events }
    }

    var sessionKeyReads: Int {
        state.withLock { $0.sessionKeyReads }
    }

    func sessionKeys() async throws(PolymarketSessionKeyError) -> [PolymarketSessionKey] {
        let read = state.withLock { state -> Result<[PolymarketSessionKey], PolymarketSessionKeyError> in
            state.sessionKeyReads += 1

            if !state.readFailures.isEmpty {
                return .failure(state.readFailures.removeFirst())
            }

            if !state.authorizations.isEmpty, !state.readFailuresAfterAuthorization.isEmpty {
                return .failure(state.readFailuresAfterAuthorization.removeFirst())
            }

            return .success(earlierRecords + state.listings.keys.sorted().compactMap { address in
                let validityShift = listedValidityShift + (state.authorized.contains(address) ? 0 : unauthorizedValidityShift)

                return state.nextStatus(of: address).map {
                    PolymarketSessionKeyManagerTests.key(
                        address: address,
                        status: $0,
                        isEnabled: !state.disabled.contains(address),
                        validityShift: validityShift
                    )
                }
            })
        }

        return try read.get()
    }

    func authorize(_ authorization: PolymarketSessionKeyAuthorization) async throws(PolymarketSessionKeyError) -> PolymarketSessionKey {
        let address = authorization.grant.sessionKeyAddress

        let failure = state.withLock { state in
            state.authorizations.append(authorization)
            return state.receive(.authorize, of: address)
        }

        if let failure {
            throw failure
        }

        return PolymarketSessionKeyManagerTests.key(address: address, status: .pending)
    }

    func revoke(_ revocation: PolymarketSessionKeyRevocation) async throws(PolymarketSessionKeyError) -> PolymarketSessionKey {
        let address = revocation.sessionKeyAddress

        let failure = state.withLock { state in
            state.revocations.append(revocation)
            return state.receive(.revoke, of: address)
        }

        if let failure {
            throw failure
        }

        return PolymarketSessionKeyManagerTests.key(address: address, status: .revoking)
    }

    func setEnabled(_ isEnabled: Bool, sessionKeyAddress: String) async throws(PolymarketSessionKeyError) -> PolymarketSessionKey {
        let failure = state.withLock { state -> PolymarketSessionKeyError? in
            guard state.setEnabledFailures.isEmpty else {
                return state.setEnabledFailures.removeFirst()
            }

            state.events.append(.setEnabled(isEnabled))

            if isEnabled {
                state.disabled.remove(sessionKeyAddress)
            } else {
                state.disabled.insert(sessionKeyAddress)
            }

            return nil
        }

        if let failure {
            throw failure
        }

        return PolymarketSessionKeyManagerTests.key(address: sessionKeyAddress, status: .active, isEnabled: isEnabled)
    }

    private struct State {
        var listings: [String: [PolymarketSessionKey.Status?]]
        var disabled: Set<String>
        let afterAuthorization: [PolymarketSessionKey.Status?]
        let afterRevocation: [PolymarketSessionKey.Status?]
        var authorizeFailures: [Failure]
        var revokeFailures: [Failure]
        var setEnabledFailures: [PolymarketSessionKeyError]
        var readFailures: [PolymarketSessionKeyError]
        var readFailuresAfterAuthorization: [PolymarketSessionKeyError]
        var authorizations: [PolymarketSessionKeyAuthorization] = []
        var revocations: [PolymarketSessionKeyRevocation] = []
        var events: [Event] = []
        var authorized: Set<String> = []
        var sessionKeyReads = 0

        mutating func receive(_ event: Event, of address: String) -> PolymarketSessionKeyError? {
            let failure: Failure?

            switch event {
            case .authorize:
                failure = authorizeFailures.isEmpty ? nil : authorizeFailures.removeFirst()
            case .revoke:
                failure = revokeFailures.isEmpty ? nil : revokeFailures.removeFirst()
            case .setEnabled:
                failure = nil
            }

            if failure?.isTaken ?? true {
                events.append(event)
                listings[address] = event == .authorize ? afterAuthorization : afterRevocation

                if event == .authorize {
                    disabled.remove(address)
                    authorized.insert(address)
                }
            }

            return failure?.error
        }

        mutating func nextStatus(of address: String) -> PolymarketSessionKey.Status? {
            guard let statuses = listings[address], let next = statuses.first else {
                return nil
            }

            if statuses.count > 1 {
                listings[address] = Array(statuses.dropFirst())
            }

            return next
        }
    }
}

private final class OwnerCredentialsSpy: PolymarketOwnerCredentialsObtaining, Sendable {
    private let isStored: Bool
    private let obtained = OSAllocatedUnfairLock(initialState: 0)

    init(hasCredentials: Bool) {
        isStored = hasCredentials
    }

    var obtainedCount: Int {
        obtained.withLock { $0 }
    }

    func hasCredentials() -> Bool {
        isStored
    }

    func obtain(authHeaders: PolymarketCLOBAuthHeaders) async {
        obtained.withLock { $0 += 1 }
    }
}

private final class PollingClockSpy: PollDelayProvider, Sendable {
    private let elapsed = OSAllocatedUnfairLock<TimeInterval>(initialState: 0)

    var now: Date {
        PolymarketSessionKeyManagerTests.now.addingTimeInterval(elapsed.withLock { $0 })
    }

    func wait(for seconds: TimeInterval) async throws {
        elapsed.withLock { $0 += seconds }
    }
}

private actor RouterSpy: PolymarketOrderSigningRouting {
    private(set) var invalidations = 0
    private(set) var readyRoutes = 0
    private let notReadyChecks: Int
    private var checks = 0
    private var remembersNotReady = false

    init(notReadyChecks: Int = 0) {
        self.notReadyChecks = notReadyChecks
    }

    nonisolated var refusalsPublisher: AnyPublisher<Void, Never> {
        .empty
    }

    func route() -> PolymarketOrderSigningRoute {
        guard !remembersNotReady else { return .ownerKey }

        checks += 1

        guard checks > notReadyChecks else {
            remembersNotReady = true
            return .ownerKey
        }

        readyRoutes += 1

        return .sessionKey(
            PolymarketSessionCredentials(
                sessionKeyAddress: PolymarketSessionKeyManagerTests.localAddress,
                credentials: PolymarketL2Credentials(apiKey: "session", secret: "c2VjcmV0", passphrase: "phrase")
            )
        )
    }

    func reportRefused(sessionKeyAddress: String) {}

    func invalidate(sessionKeyAddress: String) {
        invalidations += 1
        remembersNotReady = false
    }

    func forgetReadiness() {
        remembersNotReady = false
    }

    nonisolated func refusal(of sessionKeyAddress: String) -> PolymarketOrderSigningRefusal? {
        nil
    }
}
