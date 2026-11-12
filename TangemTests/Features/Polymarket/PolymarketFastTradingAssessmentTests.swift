//
//  PolymarketFastTradingAssessmentTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPolymarket
@testable import Tangem

@Suite("Polymarket fast trading: what this device does next")
struct PolymarketFastTradingStatusTests {
    @Test("A wallet with no session keys is offered fast trading")
    func noKeysOffersEnabling() {
        let assessment = Fixture.assess(keys: [])

        #expect(assessment.status == .offerEnable)
    }

    @Test("The local key that is being enabled waits for the relayer")
    func pendingLocalKeyIsEnabling() {
        let key = Fixture.key(.local, status: .pending, authorizedAt: nil, createdAt: Fixture.now.addingTimeInterval(-60))

        #expect(Fixture.assess(keys: [key]).status == .enabling(key))
    }

    @Test("The local key that is being revoked waits for the relayer")
    func revokingLocalKeyIsRevoking() {
        let key = Fixture.key(.local, status: .revoking)

        #expect(Fixture.assess(keys: [key]).status == .revoking(key))
    }

    @Test("An active and enabled local key trades")
    func activeLocalKeyTrades() {
        let key = Fixture.key(.local)

        #expect(Fixture.assess(keys: [key], signers: [.matching(key)]).status == .active(key))
    }

    @Test("An active local key switched off stays paused")
    func switchedOffLocalKeyIsPaused() {
        let key = Fixture.key(.local, isEnabled: false)

        #expect(Fixture.assess(keys: [key], signers: [.matching(key)]).status == .paused(key))
    }

    @Test(
        "A local key that stopped working is enabled again with the same key",
        arguments: [PolymarketSessionKey.Status.revoked, .expired]
    )
    func stoppedLocalKeyIsEnabledAgain(_ status: PolymarketSessionKey.Status) {
        let key = Fixture.key(.local, status: status)

        #expect(Fixture.assess(keys: [key]).status == .reenable(key))
    }

    @Test("An active local key past its validity is enabled again")
    func expiredActiveLocalKeyIsEnabledAgain() {
        let key = Fixture.key(.local, validUntil: Fixture.now.addingTimeInterval(-1))

        #expect(Fixture.assess(keys: [key]).status == .reenable(key))
    }

    @Test("An active local key the exchange no longer lists is enabled again")
    func localKeyMissingOnTheExchangeIsEnabledAgain() {
        let key = Fixture.key(.local)

        #expect(Fixture.assess(keys: [key], signers: []).status == .reenable(key))
    }

    @Test("An active local key the exchange lists with other terms is not repaired: its signer is unknown and signs nothing")
    func localKeyReRegisteredOnTheExchangeIsNotRepaired() {
        let key = Fixture.key(.local)
        let signer = PolymarketSessionSigner(address: key.address, scopes: key.scopes, validUntil: key.validUntil?.addingTimeInterval(Fixture.day))

        let assessment = Fixture.assess(keys: [key], signers: [signer])

        #expect(assessment.status == .active(key))
        #expect(assessment.foreignSigners == [signer])
        #expect(!assessment.isUsableOnExchange(key, at: Fixture.now))
        #expect(PolymarketFastTradingAuthorization(assessment: assessment) == nil)
    }

    @Test("A failed local key the exchange lists anyway is repaired by renewal, whatever terms it is listed with", arguments: [["CLOB"], ["ALL"]])
    func failedLocalKeyOnTheExchangeIsRenewed(_ scopes: [String]) {
        let key = Fixture.key(.local, status: .failed)
        let signer = PolymarketSessionSigner(address: key.address, scopes: scopes, validUntil: key.validUntil)

        #expect(Fixture.assess(keys: [key], signers: [signer]).status == .repairByRenewal(key))
    }

    @Test("A failed local key the exchange does not list is enabled again")
    func failedLocalKeyIsEnabledAgain() {
        let key = Fixture.key(.local, status: .failed)

        #expect(Fixture.assess(keys: [key], signers: []).status == .reenable(key))
    }

    @Test("A failed local key whose exchange list can't be read is shown as a failed read, not as a wait that reads again for half an hour")
    func failedLocalKeyWithoutTheExchangeListIsAFailedRead() {
        let key = Fixture.key(.local, status: .failed)

        let assessment = Fixture.assess(keys: [key], signers: nil)

        #expect(assessment.status == .exchangeUnreadable(key))
        #expect(!assessment.needsFollowUpReads)
    }

    @Test(
        "A previous key of this device that is still changing is waited for",
        arguments: [PolymarketSessionKey.Status.pending, .revoking]
    )
    func settlingPreviousKeyIsAwaited(_ status: PolymarketSessionKey.Status) {
        let previous = Fixture.key(.previous, status: status, createdAt: Fixture.now.addingTimeInterval(-60))

        #expect(Fixture.assess(keys: [previous]).status == .waitingForSettlement(previous))
    }

    @Test(
        "A change still settling on another device holds the repair or the replacement of this device's key",
        arguments: [Fixture.key(.local, validUntil: Fixture.now.addingTimeInterval(-1)), Fixture.key(.previous)]
    )
    func settlingKeyOfAnotherDeviceHoldsRepair(_ key: PolymarketSessionKey) {
        let settling = Fixture.key(.otherDevice, status: .pending, createdAt: Fixture.now.addingTimeInterval(-60))

        let assessment = Fixture.assess(keys: [key, settling], signers: [.matching(key), .matching(settling)])

        #expect(assessment.status == .waitingForSettlement(settling))
    }

    @Test(
        "A key left pending past the deadline of its signed batch no longer holds anything",
        arguments: [PolymarketSessionKeyFixtures.Owner.otherDevice, .previous]
    )
    func stalePendingKeyIsIgnored(_ owner: PolymarketSessionKeyFixtures.Owner) {
        let stale = Fixture.key(owner, status: .pending, authorizedAt: nil, createdAt: Fixture.now.addingTimeInterval(-Fixture.batchExecutionWindow))

        let assessment = Fixture.assess(keys: [stale])

        #expect(assessment.status == .offerEnable)
        #expect(!assessment.hasSettlingChange)
    }

    @Test("A pending key is waited for as long as the relayer can still execute its signed batch")
    func pendingKeyIsAwaitedUntilItsBatchDeadline() {
        let pending = Fixture.key(.otherDevice, status: .pending, authorizedAt: nil, createdAt: Fixture.now.addingTimeInterval(1 - Fixture.batchExecutionWindow))

        #expect(Fixture.assess(keys: [pending]).status == .waitingForSettlement(pending))
    }

    @Test(
        "A local key left pending past the deadline of its signed batch is offered again only once the backend stops holding it pending",
        arguments: zip([Fixture.batchExecutionWindow - 1, Fixture.batchExecutionWindow], [false, true])
    )
    func stalePendingLocalKeyIsEnabledAgainOnceTheBackendDropsIt(_ pendingFor: TimeInterval, _ isOffered: Bool) {
        let key = Fixture.key(.local, status: .pending, authorizedAt: nil, createdAt: Fixture.now.addingTimeInterval(-pendingFor))

        let assessment = Fixture.assess(keys: [key])

        #expect(assessment.status == (isOffered ? .reenable(key) : .enabling(key)))
        #expect(PolymarketFastTradingAuthorization(assessment: assessment) == (isOffered ? .reenable : nil))
    }

    @Test(
        "Another device's pending key holds past a plain authorization's deadline whatever else the wallet lists, since a renewal may have rewritten its record",
        arguments: [
            [Fixture.key(.local)],
            [Fixture.key(.previous, status: .revoked)],
            [],
        ] as [[PolymarketSessionKey]]
    )
    func pendingKeyOfAnotherDeviceHoldsForAFollowUpBatch(_ otherRecords: [PolymarketSessionKey]) {
        let pending = Fixture.key(.otherDevice, status: .pending, authorizedAt: nil, createdAt: Fixture.now.addingTimeInterval(-Fixture.plainBatchExecutionWindow))

        #expect(Fixture.assess(keys: otherRecords + [pending], signers: nil).hasSettlingChange)
    }

    @Test(
        "Another device's key holds changes only while its revocation can still run",
        arguments: zip([Fixture.batchExecutionWindow - 1, Fixture.batchExecutionWindow], [true, false])
    )
    func revokingKeyHoldsWhileItsRevocationCanRun(_ revokingFor: TimeInterval, _ isHeld: Bool) {
        let revoking = Fixture.key(.otherDevice, status: .revoking)

        let assessment = Fixture.assess(keys: [revoking], revokingSince: [revoking.address: Fixture.now.addingTimeInterval(-revokingFor)])

        #expect(assessment.hasSettlingChange == isHeld)
        #expect(PolymarketFastTradingAuthorization(assessment: assessment) == (isHeld ? nil : .enable))
    }

    @Test(
        "This device's key waits for its revocation only while the backend can still hold it, then is offered again",
        arguments: zip(
            [Fixture.batchExecutionWindow - 1, Fixture.batchExecutionWindow],
            [
                PolymarketFastTradingAssessment.Status.revoking(Fixture.key(.local, status: .revoking)),
                .reenable(Fixture.key(.local, status: .revoking)),
            ]
        )
    )
    func revokingLocalKeyWaitsOnlyWhileTheBackendHoldsIt(_ revokingFor: TimeInterval, _ status: PolymarketFastTradingAssessment.Status) {
        let key = Fixture.key(.local, status: .revoking)

        let assessment = Fixture.assess(keys: [key], revokingSince: [key.address: Fixture.now.addingTimeInterval(-revokingFor)])

        #expect(assessment.status == status)
    }

    @Test(
        "A local key this app is activating or renewing keeps enabling however long the relayer takes, one nobody authorizes is offered again",
        arguments: zip(
            [[PolymarketFastTradingOperation.activation], [.renewal], []],
            [
                PolymarketFastTradingAssessment.Status.enabling(Self.longPendingLocalKey),
                .enabling(Self.longPendingLocalKey),
                .reenable(Self.longPendingLocalKey),
            ]
        )
    )
    func localKeyBeingAuthorizedKeepsEnabling(_ operations: [PolymarketFastTradingOperation], _ status: PolymarketFastTradingAssessment.Status) {
        #expect(Fixture.assess(keys: [Self.longPendingLocalKey], operations: operations).status == status)
    }

    private static let longPendingLocalKey = Fixture.key(
        .local,
        status: .pending,
        authorizedAt: nil,
        createdAt: Fixture.now.addingTimeInterval(-2 * Fixture.batchExecutionWindow)
    )

    @Test(
        "A local key the exchange refused is no longer active: it is repaired, enabled again or shown as a failed read of the exchange's list",
        arguments: zip(
            [[PolymarketSessionSigner.matching(Fixture.key(.local))], [], nil] as [[PolymarketSessionSigner]?],
            [
                PolymarketFastTradingAssessment.Status.repairByRenewal(Fixture.key(.local)),
                .reenable(Fixture.key(.local)),
                .exchangeUnreadable(Fixture.key(.local)),
            ]
        )
    )
    func refusedLocalKeyIsNotActive(_ signers: [PolymarketSessionSigner]?, _ status: PolymarketFastTradingAssessment.Status) {
        let assessment = Fixture.assess(keys: [Fixture.key(.local)], signers: signers, isLocalKeyRefused: true)

        #expect(assessment.status == status)
        #expect(assessment.isOutOfSyncWithExchange(Fixture.key(.local)))
    }

    @Test("This device's working key keeps trading while another key of the wallet is changing")
    func activeLocalKeyTradesWhileAnotherKeySettles() {
        let key = Fixture.key(.local)
        let settling = Fixture.key(.otherDevice, status: .revoking)

        let assessment = Fixture.assess(keys: [settling, key], signers: [.matching(key), .matching(settling)])

        #expect(assessment.status == .active(key))
        #expect(assessment.hasSettlingChange)
    }

    @Test("A previous active key of this device is revoked and replaced in one tap")
    func activePreviousKeyIsReplacedWithRevocation() {
        let previous = Fixture.key(.previous)

        let status = Fixture.assess(keys: [previous], signers: [.matching(previous)]).status

        #expect(status == .replace(previous: previous, revokesPrevious: true))
    }

    @Test("A previous key the exchange no longer lists is replaced without a revocation")
    func previousKeyMissingOnTheExchangeIsReplacedWithoutRevocation() {
        let previous = Fixture.key(.previous)

        let status = Fixture.assess(keys: [previous], signers: []).status

        #expect(status == .replace(previous: previous, revokesPrevious: false))
    }

    @Test("A previous key waits for the exchange's list before its revocation is decided")
    func previousKeyWaitsForTheExchangeList() {
        let previous = Fixture.key(.previous)

        #expect(Fixture.assess(keys: [previous], signers: nil).status == .exchangeUnreadable(previous))
    }

    @Test(
        "A previous key of this device is replaced even when the local key needs enabling again or a repair",
        arguments: [
            Fixture.key(.local, validUntil: Fixture.now.addingTimeInterval(-1)),
            Fixture.key(.local, status: .failed),
        ]
    )
    func previousKeyIsReplacedBeforeTheLocalKeyIsFixed(_ local: PolymarketSessionKey) {
        let previous = Fixture.key(.previous)

        let status = Fixture.assess(keys: [local, previous], signers: [.matching(local), .matching(previous)]).status

        #expect(status == .replace(previous: previous, revokesPrevious: true))
    }

    @Test("Of several records of the local key, the active one decides", arguments: [true, false])
    func activeRecordOfTheLocalKeyWins(_ activeFirst: Bool) {
        let active = Fixture.key(.local)
        let revoked = Fixture.key(.local, status: .revoked)

        let status = Fixture.assess(keys: activeFirst ? [active, revoked] : [revoked, active], signers: [.matching(active)]).status

        #expect(status == .active(active))
    }

    @Test("A local key in a status the app does not know is enabled again")
    func unknownLocalKeyStatusIsEnabledAgain() {
        let key = Fixture.key(.local, status: .unknown("SUSPENDED"))

        #expect(Fixture.assess(keys: [key], signers: [.matching(key)]).status == .reenable(key))
    }

    @Test("A previous key of this device that has expired leaves the device free to enable")
    func expiredPreviousKeyOffersEnabling() {
        let previous = Fixture.key(.previous, validUntil: Fixture.now.addingTimeInterval(-1))

        #expect(Fixture.assess(keys: [previous]).status == .offerEnable)
    }

    @Test("A key of another device does not change what this device does")
    func otherDeviceKeyIsIgnored() {
        let other = Fixture.key(.otherDevice)

        #expect(Fixture.assess(keys: [other], signers: [.matching(other)]).status == .offerEnable)
    }

    @Test("The local key decides before a previous key of this device")
    func localKeyComesFirst() {
        let local = Fixture.key(.local)
        let previous = Fixture.key(.previous)

        let status = Fixture.assess(keys: [previous, local], signers: [.matching(local), .matching(previous)]).status

        #expect(status == .active(local))
    }

    @Test("Addresses from any source are matched regardless of letter case")
    func addressesAreMatchedRegardlessOfCase() {
        let key = Fixture.key(.local)
        let mixedCaseAddress = "0x" + key.address.dropFirst(2).uppercased()
        let signer = PolymarketSessionSigner(address: mixedCaseAddress, scopes: key.scopes, validUntil: key.validUntil)

        let assessment = Fixture.assess(keys: [key], signers: [signer], localAddress: mixedCaseAddress)

        #expect(assessment.status == .active(key))
        #expect(assessment.foreignSigners.isEmpty)
    }

    @Test("Renewal is due in the last 30 days of the key", arguments: zip([30 * Fixture.day, 30 * Fixture.day + 1], [true, false]))
    func renewalIsDueInTheLastThirtyDays(_ validity: TimeInterval, _ isDue: Bool) {
        let key = Fixture.key(.local, validUntil: Fixture.now.addingTimeInterval(validity))

        #expect(Fixture.assess(keys: [key], signers: [.matching(key)]).isRenewDue == isDue)
    }

    @Test("A paused key is due for renewal as an active one is")
    func pausedKeyIsDueForRenewal() {
        let key = Fixture.key(.local, isEnabled: false, validUntil: Fixture.now.addingTimeInterval(12 * Fixture.day))
        let assessment = Fixture.assess(keys: [key], signers: [.matching(key)])

        #expect(assessment.status == .paused(key))
        #expect(assessment.isRenewDue)
    }

    @Test(
        "A started day counts as a whole day left before the key expires",
        arguments: zip([6 * Fixture.hour, 12 * Fixture.day + Fixture.hour], [1, 13])
    )
    func daysUntilExpiryRoundUp(_ validity: TimeInterval, _ days: Int) {
        let key = Fixture.key(.local, validUntil: Fixture.now.addingTimeInterval(validity))

        #expect(PolymarketFastTradingAssessment.daysUntilExpiry(of: key, now: Fixture.now) == days)
    }
}

@Suite("Polymarket fast trading: reconciliation with the exchange")
struct PolymarketFastTradingReconciliationTests {
    @Test("A signer the backend never recorded is foreign")
    func unrecordedSignerIsForeign() {
        let assessment = Fixture.assess(keys: [], signers: [.unrecorded])

        #expect(assessment.foreignSigners == [.unrecorded])
    }

    @Test(
        "An unrecorded signer past its validity is no threat",
        arguments: [Fixture.now.addingTimeInterval(-1), Fixture.now]
    )
    func expiredUnrecordedSignerIsNotForeign(_ validUntil: Date) {
        let signer = PolymarketSessionSigner(address: PolymarketSessionSigner.unrecorded.address, scopes: ["CLOB"], validUntil: validUntil)

        #expect(Fixture.assess(keys: [], signers: [signer]).foreignSigners.isEmpty)
    }

    @Test(
        "A signer the backend records as live or still revoking by this wallet is not foreign",
        arguments: [PolymarketSessionKey.Status.pending, .active, .revoking, .unknown("LOST")]
    )
    func recordedSignerIsNotForeign(_ status: PolymarketSessionKey.Status) {
        let key = Fixture.key(.otherDevice, status: status)

        #expect(Fixture.assess(keys: [key], signers: [.matching(key)]).foreignSigners.isEmpty)
    }

    @Test(
        "A signer the exchange still lists after the backend recorded it revoked, expired or failed is foreign",
        arguments: [PolymarketSessionKey.Status.revoked, .expired, .failed]
    )
    func endedRecordStillOnTheExchangeIsForeign(_ status: PolymarketSessionKey.Status) {
        let key = Fixture.key(.otherDevice, status: status)

        #expect(Fixture.assess(keys: [key], signers: [.matching(key)]).foreignSigners.map(\.address) == [key.address])
    }

    @Test(
        "A signer this device saw revoking is a revocation in progress for half an hour, then a foreign signer again",
        arguments: zip([29 * 60, 30 * 60] as [TimeInterval], [true, false])
    )
    func signerSeenRevokingIsInProgressForHalfAnHour(_ sinceRevoking: TimeInterval, _ isInProgress: Bool) {
        let key = Fixture.key(.otherDevice, status: .revoked)

        let assessment = Fixture.assess(
            keys: [key],
            signers: [.matching(key)],
            revokingSince: [key.address: Fixture.now.addingTimeInterval(-sinceRevoking)]
        )

        #expect(assessment.signersBeingRevoked.map(\.address) == (isInProgress ? [key.address] : []))
        #expect(assessment.foreignSigners.map(\.address) == (isInProgress ? [] : [key.address]))
    }

    @Test("The local key the exchange lists after a failure is repaired, not reported foreign")
    func failedLocalKeyIsNotForeign() {
        let key = Fixture.key(.local, status: .failed)

        #expect(Fixture.assess(keys: [key], signers: [.matching(key)]).foreignSigners.isEmpty)
    }

    @Test(
        "The local key the exchange still lists after the backend recorded it revoked or expired is foreign",
        arguments: [PolymarketSessionKey.Status.revoked, .expired]
    )
    func endedLocalKeyStillOnTheExchangeIsForeign(_ status: PolymarketSessionKey.Status) {
        let key = Fixture.key(.local, status: status)

        #expect(Fixture.assess(keys: [key], signers: [.matching(key)]).foreignSigners.map(\.address) == [key.address])
    }

    @Test(
        "The local key the exchange lists without a record of ours is foreign unless this device is authorizing it",
        arguments: zip([[], [PolymarketFastTradingOperation.activation], [.revocation]], [true, false, true])
    )
    func unrecordedLocalKeyIsForeignOutsideItsAuthorization(_ operations: [PolymarketFastTradingOperation], _ isForeign: Bool) {
        let signer = PolymarketSessionSigner.matching(Fixture.key(.local))

        #expect(Fixture.assess(keys: [], signers: [signer], operations: operations).hasForeignSigners == isForeign)
    }

    @Test(
        "The local key the exchange still lists with its old terms after the backend recorded it revoked is ours while this device authorizes it again",
        arguments: [PolymarketFastTradingOperation.renewal, .activation]
    )
    func revokedLocalKeyIsOursWhileReauthorized(_ operation: PolymarketFastTradingOperation) {
        let key = Fixture.key(.local, status: .revoked)
        let assessment = Fixture.assess(keys: [key], signers: [.matching(key)], operations: [operation])

        #expect(assessment.foreignSigners.isEmpty)
        #expect(assessment.signersBeingRevoked.isEmpty)
    }

    @Test("An active key the exchange lists with exactly the CLOB scope, in any letter case, and the key's validity is ours")
    func exactTermsKeepTheSignerOurs() {
        let key = Fixture.key(.otherDevice)
        let signer = PolymarketSessionSigner(address: key.address, scopes: ["clob"], validUntil: key.validUntil)

        let assessment = Fixture.assess(keys: [key], signers: [signer])

        #expect(assessment.reRegisteredOnExchange.isEmpty)
        #expect(assessment.foreignSigners.isEmpty)
    }

    @Test(
        "An active key the exchange lists with another scope or a validity off by even a second was registered again behind our back: its signer is unknown, the key isn't out of sync",
        arguments: [
            (["ALL"], TimeInterval.zero),
            (["CLOB", "ALL"], .zero),
            ([], .zero),
            (["CLOB"], 1),
            (["CLOB"], Fixture.day),
        ]
    )
    func otherTermsAreReRegistered(_ scopes: [String], _ validityShift: TimeInterval) {
        let key = Fixture.key(.otherDevice)
        let signer = PolymarketSessionSigner(address: key.address, scopes: scopes, validUntil: key.validUntil?.addingTimeInterval(validityShift))

        let assessment = Fixture.assess(keys: [key], signers: [signer])

        #expect(assessment.reRegisteredOnExchange == [key.address])
        #expect(assessment.foreignSigners == [signer])
        #expect(!assessment.isOutOfSyncWithExchange(key))
    }

    @Test("A local key the exchange lists without a validity can't sign and its signer is unknown, without a repair")
    func signerWithoutValidityIsUnknown() {
        let key = Fixture.key(.local)
        let signer = PolymarketSessionSigner(address: key.address, scopes: key.scopes, validUntil: nil)

        let assessment = Fixture.assess(keys: [key], signers: [signer])

        #expect(!assessment.isUsableOnExchange(key, at: Fixture.now))
        #expect(assessment.reRegisteredOnExchange == [key.address])
        #expect(assessment.status == .active(key))
    }

    @Test("An active key without an authorization date is checked against the exchange once it is past the grace period")
    func keyWithoutAuthorizationDateIsReconciled() {
        let key = Fixture.key(.local, authorizedAt: nil, createdAt: Fixture.now.addingTimeInterval(-Fixture.day))

        let assessment = Fixture.assess(keys: [key], signers: [])

        #expect(assessment.missingOnExchange == [key.address])
        #expect(assessment.status == .reenable(key))
    }

    @Test("A key renewed moments ago that the exchange still lists with its old validity is in sync")
    func freshlyRenewedKeyIsInSync() {
        let key = Fixture.key(.otherDevice, authorizedAt: Fixture.now.addingTimeInterval(-60))
        let signer = PolymarketSessionSigner(address: key.address, scopes: key.scopes, validUntil: key.validUntil?.addingTimeInterval(-Fixture.day))

        let assessment = Fixture.assess(keys: [key], signers: [signer])

        #expect(assessment.reRegisteredOnExchange.isEmpty)
        #expect(assessment.foreignSigners.isEmpty)
    }

    @Test("A key that turned active moments ago is not reported missing on the exchange")
    func freshKeyIsNotMissing() {
        let key = Fixture.key(.otherDevice, authorizedAt: Fixture.now.addingTimeInterval(-60))

        #expect(Fixture.assess(keys: [key], signers: []).missingOnExchange.isEmpty)
    }

    @Test("An active key the exchange does not list is reported missing")
    func unlistedKeyIsMissing() {
        let key = Fixture.key(.otherDevice)

        #expect(Fixture.assess(keys: [key], signers: []).missingOnExchange == [key.address])
    }

    @Test(
        "A refusal is lifted only by a record or a listing that changed after it, never by the ones the refused order was routed on",
        arguments: [
            (PolymarketSessionKeyConfirmation(record: Fixture.key(.local), signer: .matching(Fixture.key(.local))), false),
            (PolymarketSessionKeyConfirmation(record: Fixture.key(.local).withMixedCaseAddress, signer: PolymarketSessionSigner.matching(Fixture.key(.local).withMixedCaseAddress)), false),
            (PolymarketSessionKeyConfirmation(record: Fixture.key(.local, authorizedAt: Fixture.now.addingTimeInterval(-2 * Fixture.day)), signer: .matching(Fixture.key(.local))), false),
            (PolymarketSessionKeyConfirmation(record: Fixture.key(.local).renamed, signer: .matching(Fixture.key(.local))), false),
            (PolymarketSessionKeyConfirmation(record: Fixture.key(.local, validUntil: Fixture.validUntil.addingTimeInterval(-Fixture.day)), signer: .matching(Fixture.key(.local))), true),
            (PolymarketSessionKeyConfirmation(record: Fixture.key(.local, isEnabled: false), signer: .matching(Fixture.key(.local))), true),
            (PolymarketSessionKeyConfirmation(record: Fixture.key(.local), signer: PolymarketSessionSigner(address: Fixture.localAddress, scopes: ["ALL"], validUntil: Fixture.validUntil)), true),
            (nil, false),
        ] as [(PolymarketSessionKeyConfirmation?, Bool)]
    )
    func refusalIsLiftedByNewerEvidenceOnly(_ routedOn: PolymarketSessionKeyConfirmation?, _ isLifted: Bool) {
        let key = Fixture.key(.local)
        let snapshot = PolymarketFastTradingSnapshot(
            sessionKeys: [key],
            localKeyAddress: Fixture.localAddress,
            deviceId: Fixture.deviceId,
            signers: [.matching(key)],
            now: Fixture.now
        )
        let refusal = PolymarketOrderSigningRefusal(refusedAt: Fixture.now, routedOn: routedOn)

        #expect(PolymarketFastTradingAssessment.confirmsLocalKey(after: refusal, in: snapshot) == isLifted)
    }

    @Test("Without the exchange's list nothing is reported foreign, missing or out of sync")
    func unknownSignersReportNothing() {
        let key = Fixture.key(.local)

        let assessment = Fixture.assess(keys: [key], signers: nil)

        #expect(assessment.foreignSigners.isEmpty)
        #expect(assessment.missingOnExchange.isEmpty)
        #expect(assessment.reRegisteredOnExchange.isEmpty)
        #expect(assessment.status == .active(key))
    }
}

@Suite("Polymarket fast trading: banners on the predictions screens")
struct PolymarketFastTradingBannerTests {
    @Test("Foreign signers outrank every other banner and can't be dismissed")
    func foreignSignersComeFirst() {
        let key = Fixture.key(.local, validUntil: Fixture.now.addingTimeInterval(12 * Fixture.day))
        let state = PolymarketFastTradingState.loaded(Fixture.assess(keys: [key], signers: [.matching(key), .unrecorded]))

        #expect(PolymarketFastTradingBanner(state: state, includingForeignSigners: true, isDismissed: { _ in true }) == .foreignSigners)
    }

    @Test("The foreign signer warning stays up while an operation of this app runs")
    func foreignSignersShowDuringAnOperation() {
        let assessment = Fixture.assess(keys: [], signers: [.unrecorded], operations: [.activation])

        #expect(PolymarketFastTradingBanner(state: .loaded(assessment), includingForeignSigners: true, isDismissed: { _ in false }) == .foreignSigners)
    }

    @Test(
        "A screen without the foreign signer warning still asks to activate or extend this device's key",
        arguments: zip(
            [[], [Fixture.key(.local, validUntil: Fixture.now.addingTimeInterval(12 * Fixture.day))]] as [[PolymarketSessionKey]],
            [PolymarketFastTradingBanner.activate, .extend(daysLeft: 12)]
        )
    )
    func keyBannerShowsDespiteForeignSigners(_ keys: [PolymarketSessionKey], _ banner: PolymarketFastTradingBanner) {
        let signers = keys.map(PolymarketSessionSigner.matching) + [.unrecorded]
        let state = PolymarketFastTradingState.loaded(Fixture.assess(keys: keys, signers: signers))

        #expect(PolymarketFastTradingBanner(state: state, includingForeignSigners: false, isDismissed: { _ in false }) == banner)
    }

    @Test("A key in its last 30 days asks to extend it and says how many days are left")
    func extensionBanner() {
        let key = Fixture.key(.local, validUntil: Fixture.now.addingTimeInterval(12 * Fixture.day))
        let state = PolymarketFastTradingState.loaded(Fixture.assess(keys: [key], signers: [.matching(key)]))

        #expect(PolymarketFastTradingBanner(state: state, includingForeignSigners: true, isDismissed: { _ in false }) == .extend(daysLeft: 12))
    }

    @Test("A device that never had a key of its own is asked to activate", arguments: [[PolymarketSessionKey](), [Fixture.key(.previous)]])
    func activationBanner(_ keys: [PolymarketSessionKey]) {
        let state = PolymarketFastTradingState.loaded(Fixture.assess(keys: keys))

        #expect(PolymarketFastTradingBanner(state: state, includingForeignSigners: true, isDismissed: { _ in false }) == .activate)
    }

    @Test(
        "A device whose key stopped working is asked to reactivate even after the activation banner was closed, one whose key the user revoked is offered the activation",
        arguments: zip([PolymarketSessionKey.Status.expired, .revoked], [PolymarketFastTradingBanner.reactivate, .activate])
    )
    func reactivationBannerIgnoresClosedActivation(_ status: PolymarketSessionKey.Status, _ banner: PolymarketFastTradingBanner) {
        let state = PolymarketFastTradingState.loaded(Fixture.assess(keys: [Fixture.key(.local, status: status)]))

        #expect(PolymarketFastTradingBanner(state: state, includingForeignSigners: true, isDismissed: { _ in false }) == banner)
        #expect(
            PolymarketFastTradingBanner(state: state, includingForeignSigners: true, isDismissed: { $0 == .activate })
                == (banner == .activate ? nil : banner)
        )
    }

    @Test(
        "A device whose key failed to activate is asked to activate, not to reactivate",
        arguments: [
            [Fixture.key(.local, status: .failed)],
            [Fixture.key(.local, status: .pending, authorizedAt: nil, createdAt: Fixture.now.addingTimeInterval(-Fixture.batchExecutionWindow))],
        ]
    )
    func failedActivationAsksToActivate(_ keys: [PolymarketSessionKey]) {
        let state = PolymarketFastTradingState.loaded(Fixture.assess(keys: keys))

        #expect(PolymarketFastTradingBanner(state: state, includingForeignSigners: true, isDismissed: { _ in false }) == .activate)
    }

    @Test(
        "A closed banner hides only its own kind",
        arguments: PolymarketFastTradingBanner.DismissibleKind.allCases, PolymarketFastTradingBanner.DismissibleKind.allCases
    )
    func dismissalHidesItsKindOnly(_ shown: PolymarketFastTradingBanner.DismissibleKind, _ closed: PolymarketFastTradingBanner.DismissibleKind) {
        let banner = PolymarketFastTradingBanner(state: Self.state(showing: shown), includingForeignSigners: true, isDismissed: { $0 == closed })

        #expect(banner?.dismissibleKind == (shown == closed ? nil : shown))
    }

    @Test(
        "A closed activation or extension banner stays hidden for 30 days and comes back after",
        arguments: [PolymarketFastTradingBanner.DismissibleKind.activate, .extend],
        Array(zip([nil, 29 * Fixture.day, 30 * Fixture.day] as [TimeInterval?], [false, true, false]))
    )
    func dismissalLastsThirtyDays(_ kind: PolymarketFastTradingBanner.DismissibleKind, _ closed: (ago: TimeInterval?, isHidden: Bool)) {
        let dismissedAt = closed.ago.map { Fixture.now.addingTimeInterval(-$0) }

        #expect(kind.isDismissed(dismissedAt: dismissedAt, now: Fixture.now) == closed.isHidden)
    }

    @Test(
        "A closed reactivation banner comes back the next day",
        arguments: zip([23 * Fixture.hour, Fixture.day], [true, false])
    )
    func reactivationDismissalLastsADay(_ closedAgo: TimeInterval, _ isHidden: Bool) {
        let dismissedAt = Fixture.now.addingTimeInterval(-closedAgo)

        #expect(PolymarketFastTradingBanner.DismissibleKind.reactivate.isDismissed(dismissedAt: dismissedAt, now: Fixture.now) == isHidden)
    }

    @Test("Nothing is shown while the state is unknown", arguments: [PolymarketFastTradingState.loading, .failed])
    func unknownStateShowsNothing(_ state: PolymarketFastTradingState) {
        #expect(PolymarketFastTradingBanner(state: state, includingForeignSigners: true, isDismissed: { _ in false }) == nil)
    }

    private static func state(showing kind: PolymarketFastTradingBanner.DismissibleKind) -> PolymarketFastTradingState {
        switch kind {
        case .activate:
            return .loaded(Fixture.assess(keys: []))
        case .reactivate:
            return .loaded(Fixture.assess(keys: [Fixture.key(.local, status: .expired)]))
        case .extend:
            let key = Fixture.key(.local, validUntil: Fixture.now.addingTimeInterval(12 * Fixture.day))
            return .loaded(Fixture.assess(keys: [key], signers: [.matching(key)]))
        }
    }
}

@Suite("Polymarket fast trading: what the Activate button signs")
struct PolymarketFastTradingAuthorizationTests {
    @Test("A wallet without keys enables fast trading")
    func offerEnables() {
        #expect(PolymarketFastTradingAuthorization(assessment: Fixture.assess(keys: [])) == .enable)
    }

    @Test("A stopped local key is enabled again")
    func stoppedKeyReenables() {
        #expect(PolymarketFastTradingAuthorization(assessment: Fixture.assess(keys: [Fixture.key(.local, status: .expired)])) == .reenable)
    }

    @Test("A key the user revoked is activated anew, with the verb its banner uses")
    func revokedKeyIsActivatedAnew() throws {
        let assessment = Fixture.assess(keys: [Fixture.key(.local, status: .revoked)])
        let authorization = try #require(PolymarketFastTradingAuthorization(assessment: assessment))

        #expect(authorization == .enable)
        #expect(PolymarketFastTradingBanner(state: .loaded(assessment), includingForeignSigners: true, isDismissed: { _ in false }) == .activate)
        #expect(PolymarketFastTradingDevice.Action(authorization: authorization) == .activate)
    }

    @Test("A key due for renewal is extended")
    func renewDueRenews() {
        let key = Fixture.key(.local, validUntil: Fixture.now.addingTimeInterval(12 * Fixture.day))

        #expect(PolymarketFastTradingAuthorization(assessment: Fixture.assess(keys: [key], signers: [.matching(key)])) == .renew)
    }

    @Test("A failed local key the exchange lists anyway is repaired by renewing it")
    func failedListedKeyIsRepaired() {
        let key = Fixture.key(.local, status: .failed)

        #expect(PolymarketFastTradingAuthorization(assessment: Fixture.assess(keys: [key], signers: [.matching(key)])) == .repair)
    }

    @Test("A failed local key is not repaired before the exchange's list is read")
    func failedKeyWaitsForTheExchangeList() {
        let key = Fixture.key(.local, status: .failed)

        #expect(PolymarketFastTradingAuthorization(assessment: Fixture.assess(keys: [key], signers: nil)) == nil)
    }

    @Test("A key left by a previous install of this device is replaced")
    func previousKeyIsReplaced() {
        let previous = Fixture.key(.previous)

        let authorization = PolymarketFastTradingAuthorization(assessment: Fixture.assess(keys: [previous], signers: [.matching(previous)]))

        #expect(authorization == .replace(previous: previous, revokesPrevious: true))
    }

    @Test("A working or changing key needs no authorization", arguments: [PolymarketSessionKey.Status.active, .pending, .revoking])
    func nothingToAuthorize(_ status: PolymarketSessionKey.Status) {
        let key = Fixture.key(.local, status: status)

        #expect(PolymarketFastTradingAuthorization(assessment: Fixture.assess(keys: [key], signers: [.matching(key)])) == nil)
    }

    @Test(
        "An operation this app is running holds every offer",
        arguments: [[PolymarketSessionKey](), [Fixture.key(.local, validUntil: Fixture.now.addingTimeInterval(12 * Fixture.day))]],
        [PolymarketFastTradingOperation.activation, .revocation, .toggle]
    )
    func operationInFlightHoldsOffers(_ keys: [PolymarketSessionKey], _ operation: PolymarketFastTradingOperation) {
        let assessment = Fixture.assess(keys: keys, signers: keys.map(PolymarketSessionSigner.matching), operations: [operation])

        #expect(PolymarketFastTradingAuthorization(assessment: assessment) == nil)
        #expect(PolymarketFastTradingBanner(state: .loaded(assessment), includingForeignSigners: true, isDismissed: { _ in false }) == nil)
    }

    @Test(
        "A change still settling on another device holds the extension of this device's key without promising an activation",
        arguments: [PolymarketSessionKey.Status.pending, .revoking]
    )
    func settlingKeyOfAnotherDeviceHoldsExtension(_ status: PolymarketSessionKey.Status) throws {
        let key = Fixture.key(.local, validUntil: Fixture.now.addingTimeInterval(12 * Fixture.day))
        let settling = Fixture.key(.otherDevice, status: status, createdAt: Fixture.now.addingTimeInterval(-60))
        let assessment = Fixture.assess(keys: [key, settling], signers: [.matching(key)])

        try #require(assessment.isRenewDue)
        #expect(PolymarketFastTradingAuthorization(assessment: assessment) == nil)
        #expect(PolymarketFastTradingBanner(state: .loaded(assessment), includingForeignSigners: true, isDismissed: { _ in false }) == nil)
        #expect(PolymarketFastTradingAuthorization.pendingChangeNotice(for: assessment) == PolymarketFastTradingStrings.changeInProgress)
    }

    @Test(
        "A change still settling tells the user what activation waits for",
        arguments: zip(
            [PolymarketSessionKey.Status.pending, .revoking],
            [PolymarketFastTradingStrings.changeInProgress, PolymarketFastTradingStrings.revocationPending]
        )
    )
    func settlingChangeIsExplained(_ status: PolymarketSessionKey.Status, _ notice: String) {
        let settling = Fixture.key(.otherDevice, status: status, createdAt: Fixture.now.addingTimeInterval(-60))
        let assessment = Fixture.assess(keys: [settling], localAddress: nil)

        #expect(PolymarketFastTradingAuthorization.pendingChangeNotice(for: assessment) == notice)
    }
}

@Suite("Polymarket fast trading: what the user is told when an operation fails")
struct PolymarketFastTradingFailureTests {
    @Test(
        "Another change still running asks to wait for it, whether the backend, the relayer or this app reports it",
        arguments: [
            PolymarketSessionKeyError.refused(statusCode: 409, reason: .busy, detail: nil) as Error,
            PolymarketSessionKeyError.refused(statusCode: 422, reason: .relayerRejected, detail: "wallet has in-flight action"),
            PolymarketSessionKeyManagerError.operationInProgress,
        ]
    )
    func changeInFlightAsksToWait(_ error: Error) {
        #expect(PolymarketFastTradingFailure(error: error) == .busy)
    }

    @Test("An authorization still settling when this app stops waiting is not reported as a failure, its key keeps showing as activating")
    func unsettledAuthorizationIsNotAFailure() {
        let error = PolymarketSessionKeyManagerError.unsettled(Fixture.key(.local, status: .pending))

        #expect(PolymarketFastTradingFailure(error: error) == nil)
    }

    @Test("A failure with no known cause is reported as an unknown error, not as an expired signature")
    func unexplainedFailureIsGeneric() {
        #expect(PolymarketFastTradingFailure(error: PolymarketSessionKeyManagerError.unparseableNonce("abc")) == .generic)
    }

    @Test("A relayer rejection asks to sign again, as a used nonce does")
    func relayerRejectionAsksToSignAgain() {
        let error = PolymarketSessionKeyError.refused(statusCode: 422, reason: .relayerRejected, detail: nil)

        #expect(PolymarketFastTradingFailure(error: error) == .staleSignature)
    }

    @Test("A refusal from the backend is mapped by its reason")
    func refusalUsesItsReason() {
        let error = PolymarketSessionKeyError.refused(statusCode: 409, reason: .walletNotReady, detail: nil)

        #expect(PolymarketFastTradingFailure(error: error) == .notReady)
    }

    @Test(
        "Cancellation is never reported as a failure",
        arguments: [PolymarketSigningError.cancelled as Error, PolymarketSessionKeyError.cancelled, CancellationError()]
    )
    func cancellationIsSilent(_ error: Error) {
        #expect(PolymarketFastTradingFailure(error: error) == nil)
    }

    @Test(
        "A failed request is logged without the address it was sent to, which carries the wallet id",
        arguments: [
            PolymarketSessionKeyError.other(.connection(underlying: Self.failedRequest)) as Error,
            PolymarketAPIError.connection(underlying: Self.failedRequest),
            Self.failedRequest,
        ]
    )
    func failedRequestIsLoggedWithoutTheWalletId(_ error: Error) {
        let description = PolymarketFastTradingFailure.logDescription(of: error)

        #expect(!description.contains(Self.walletId))
        #expect(description.contains(String(URLError.Code.timedOut.rawValue)))
    }

    private static let walletId = "c0ffee00c0ffee00c0ffee00c0ffee00c0ffee00c0ffee00c0ffee00c0ffee00"

    private static var failedRequest: URLError {
        URLError(.timedOut, userInfo: [NSURLErrorFailingURLStringErrorKey: "https://bff.example/api/predictions/v1/wallet?walletId=\(walletId)"])
    }
}

@Suite("Polymarket fast trading: offers only when this device truly has no usable key")
struct PolymarketFastTradingOfferGatingTests {
    @Test("A key left by an earlier install of the app on this phone is another device's key")
    func keyOfAnEarlierInstallIsForeignToThisInstall() {
        let leftover = Fixture.key(.otherDevice)
        let assessment = Fixture.assess(keys: [leftover], signers: [.matching(leftover)], localAddress: nil)
        let devices = PolymarketFastTradingDevice.devices(from: assessment, thisDeviceName: Fixture.deviceName)

        #expect(assessment.status == .offerEnable)
        #expect(devices.map(\.isThisDevice) == [false])
        #expect(PolymarketFastTradingViewModel.ThisDeviceSection(state: .loaded(assessment), thisDeviceName: Fixture.deviceName) == .activationOffer)
        #expect(PolymarketFastTradingAuthorization(assessment: assessment) == .enable)
    }
}

// MARK: - Helpers

private typealias Fixture = PolymarketSessionKeyFixtures

private extension PolymarketSessionSigner {
    static let unrecorded = PolymarketSessionSigner(
        address: "0xf0e1000000000000000000000000000000000009",
        scopes: ["CLOB"],
        validUntil: Fixture.validUntil
    )
}

private extension PolymarketSessionKey {
    var withMixedCaseAddress: PolymarketSessionKey {
        PolymarketSessionKey(
            address: "0x" + address.dropFirst(2).uppercased(),
            deviceId: deviceId,
            deviceName: deviceName,
            isEnabled: isEnabled,
            status: status,
            scopes: scopes,
            validUntil: validUntil,
            authorizedAt: authorizedAt,
            createdAt: createdAt
        )
    }

    var renamed: PolymarketSessionKey {
        PolymarketSessionKey(
            address: address,
            deviceId: deviceId,
            deviceName: "Renamed",
            isEnabled: isEnabled,
            status: status,
            scopes: scopes.map { $0.lowercased() },
            validUntil: validUntil,
            authorizedAt: authorizedAt,
            createdAt: createdAt
        )
    }
}
