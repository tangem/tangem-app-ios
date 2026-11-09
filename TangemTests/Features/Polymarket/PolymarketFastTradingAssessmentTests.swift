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

    @Test("An active local key the exchange lists with other terms is repaired by renewal")
    func localKeyOutOfSyncWithTheExchangeIsRenewed() {
        let key = Fixture.key(.local)
        let signer = PolymarketSessionSigner(address: key.address, scopes: key.scopes, validUntil: key.validUntil?.addingTimeInterval(Fixture.day))

        #expect(Fixture.assess(keys: [key], signers: [signer]).status == .repairByRenewal(key))
    }

    @Test("A failed local key the exchange lists anyway is repaired by renewal")
    func failedLocalKeyOnTheExchangeIsRenewed() {
        let key = Fixture.key(.local, status: .failed)

        #expect(Fixture.assess(keys: [key], signers: [.matching(key)]).status == .repairByRenewal(key))
    }

    @Test("A failed local key the exchange does not list is enabled again")
    func failedLocalKeyIsEnabledAgain() {
        let key = Fixture.key(.local, status: .failed)

        #expect(Fixture.assess(keys: [key], signers: []).status == .reenable(key))
    }

    @Test("A failed local key waits for the exchange's list before a repair is chosen")
    func failedLocalKeyWaitsForTheExchangeList() {
        let key = Fixture.key(.local, status: .failed)

        #expect(Fixture.assess(keys: [key], signers: nil).status == .awaitingExchangeListing(key))
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

    @Test("A key left pending for more than ten minutes no longer holds anything", arguments: [PolymarketSessionKeyFixtures.Owner.otherDevice, .previous])
    func stalePendingKeyIsIgnored(_ owner: PolymarketSessionKeyFixtures.Owner) {
        let stale = Fixture.key(owner, status: .pending, authorizedAt: nil, createdAt: Fixture.now.addingTimeInterval(-11 * 60))

        let assessment = Fixture.assess(keys: [stale])

        #expect(assessment.status == .offerEnable)
        #expect(!assessment.hasSettlingChange)
    }

    @Test("A local key left pending for more than ten minutes is enabled again")
    func stalePendingLocalKeyIsEnabledAgain() {
        let key = Fixture.key(.local, status: .pending, authorizedAt: nil, createdAt: Fixture.now.addingTimeInterval(-11 * 60))

        #expect(Fixture.assess(keys: [key]).status == .reenable(key))
    }

    @Test("A local key this app is activating keeps enabling however long the relayer takes")
    func localKeyBeingActivatedKeepsEnabling() {
        let key = Fixture.key(.local, status: .pending, authorizedAt: nil, createdAt: Fixture.now.addingTimeInterval(-11 * 60))

        #expect(Fixture.assess(keys: [key], operations: [.activation]).status == .enabling(key))
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

        #expect(Fixture.assess(keys: [previous], signers: nil).status == .awaitingExchangeListing(previous))
    }

    @Test(
        "A previous key of this device is replaced even when the local key needs enabling again or a repair",
        arguments: [
            Fixture.key(.local, validUntil: Fixture.now.addingTimeInterval(-1)),
            Fixture.key(.local, validUntil: Fixture.validUntil),
        ]
    )
    func previousKeyIsReplacedBeforeTheLocalKeyIsFixed(_ local: PolymarketSessionKey) {
        let previous = Fixture.key(.previous)
        let outOfSync = PolymarketSessionSigner(address: local.address, scopes: [], validUntil: local.validUntil)

        let status = Fixture.assess(keys: [local, previous], signers: [outOfSync, .matching(previous)]).status

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

    @Test(
        "Renewal is due once the backend's renewal date has passed",
        arguments: zip([Fixture.now, Fixture.now.addingTimeInterval(60)], [true, false])
    )
    func renewalIsDueAfterTheRenewalDate(_ renewAfter: Date, _ isDue: Bool) {
        let key = Fixture.key(.local, renewAfter: renewAfter)

        #expect(Fixture.assess(keys: [key], signers: [.matching(key)]).isRenewDue == isDue)
    }

    @Test(
        "Renewal is due in the last 30 days of the key even without a renewal date",
        arguments: zip([30 * Fixture.day, 31 * Fixture.day], [true, false])
    )
    func renewalIsDueInTheLastThirtyDays(_ validity: TimeInterval, _ isDue: Bool) {
        let key = Fixture.key(.local, validUntil: Fixture.now.addingTimeInterval(validity))

        #expect(Fixture.assess(keys: [key], signers: [.matching(key)]).isRenewDue == isDue)
    }

    @Test("A paused key is not offered an extension until it is resumed", arguments: [
        Fixture.key(.local, isEnabled: false, renewAfter: Fixture.now.addingTimeInterval(-1)),
        Fixture.key(.local, isEnabled: false, validUntil: Fixture.now.addingTimeInterval(12 * Fixture.day)),
    ])
    func pausedKeyIsNotDueForRenewal(_ key: PolymarketSessionKey) {
        let assessment = Fixture.assess(keys: [key], signers: [.matching(key)])

        #expect(assessment.status == .paused(key))
        #expect(!assessment.isRenewDue)
    }

    @Test("The backend's renewal date decides over the last 30 days of the key")
    func renewalDateDecidesOverTheLastThirtyDays() {
        let key = Fixture.key(.local, validUntil: Fixture.now.addingTimeInterval(20 * Fixture.day), renewAfter: Fixture.now.addingTimeInterval(17 * Fixture.day))

        #expect(!Fixture.assess(keys: [key], signers: [.matching(key)]).isRenewDue)
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
        "A signer the backend records as live is not foreign",
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

    @Test("The local key the exchange lists after a failure is repaired, not reported foreign")
    func failedLocalKeyIsNotForeign() {
        let key = Fixture.key(.local, status: .failed)

        #expect(Fixture.assess(keys: [key], signers: [.matching(key)]).foreignSigners.isEmpty)
    }

    @Test("An active key the exchange lists with any trading scope is in sync", arguments: [["ALL"], ["clob"]])
    func tradingScopeKeepsTheKeyInSync(_ scopes: [String]) {
        let key = Fixture.key(.otherDevice)
        let signer = PolymarketSessionSigner(address: key.address, scopes: scopes, validUntil: key.validUntil)

        let assessment = Fixture.assess(keys: [key], signers: [signer])

        #expect(assessment.mismatchedOnExchange.isEmpty)
        #expect(assessment.foreignSigners.isEmpty)
    }

    @Test(
        "An active key the exchange lists without a trading scope or with another validity is out of sync, not foreign",
        arguments: [([String](), TimeInterval.zero), (["CLOB"], Fixture.day)]
    )
    func otherTermsAreOutOfSync(_ scopes: [String], _ validityShift: TimeInterval) {
        let key = Fixture.key(.otherDevice)
        let signer = PolymarketSessionSigner(address: key.address, scopes: scopes, validUntil: key.validUntil?.addingTimeInterval(validityShift))

        let assessment = Fixture.assess(keys: [key], signers: [signer])

        #expect(assessment.mismatchedOnExchange == [key.address])
        #expect(assessment.foreignSigners.isEmpty)
    }

    @Test(
        "An active key the exchange lists without a validity or with one off by under a minute is in sync",
        arguments: [nil, Fixture.validUntil.addingTimeInterval(30)]
    )
    func validityWithinToleranceIsInSync(_ listedValidUntil: Date?) {
        let key = Fixture.key(.otherDevice)
        let signer = PolymarketSessionSigner(address: key.address, scopes: key.scopes, validUntil: listedValidUntil)

        #expect(Fixture.assess(keys: [key], signers: [signer]).mismatchedOnExchange.isEmpty)
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

        #expect(assessment.mismatchedOnExchange.isEmpty)
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

    @Test("Without the exchange's list nothing is reported foreign, missing or out of sync")
    func unknownSignersReportNothing() {
        let key = Fixture.key(.local)

        let assessment = Fixture.assess(keys: [key], signers: nil)

        #expect(assessment.foreignSigners.isEmpty)
        #expect(assessment.missingOnExchange.isEmpty)
        #expect(assessment.mismatchedOnExchange.isEmpty)
        #expect(assessment.status == .active(key))
    }
}

@Suite("Polymarket fast trading: banners on the predictions screens")
struct PolymarketFastTradingBannerTests {
    @Test("Foreign signers outrank every other banner and can't be dismissed")
    func foreignSignersComeFirst() {
        let key = Fixture.key(.local, renewAfter: Fixture.now.addingTimeInterval(-1))
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

    @Test("A device without a usable key is asked to activate", arguments: [
        [PolymarketSessionKey](),
        [Fixture.key(.local, status: .expired)],
        [Fixture.key(.local, status: .revoked)],
        [Fixture.key(.previous)],
    ])
    func activationBanner(_ keys: [PolymarketSessionKey]) {
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
        "A closed activation banner stays hidden for 30 days and comes back after",
        arguments: zip([nil, 29 * Fixture.day, 30 * Fixture.day] as [TimeInterval?], [false, true, false])
    )
    func dismissalLastsThirtyDays(_ closedAgo: TimeInterval?, _ isHidden: Bool) {
        let dismissedAt = closedAgo.map { Fixture.now.addingTimeInterval(-$0) }

        #expect(PolymarketFastTradingBanner.DismissibleKind.activate.isDismissed(dismissedAt: dismissedAt, now: Fixture.now) == isHidden)
    }

    @Test(
        "A closed extension banner comes back the next day",
        arguments: zip([23 * Fixture.hour, Fixture.day], [true, false])
    )
    func extensionDismissalLastsADay(_ closedAgo: TimeInterval, _ isHidden: Bool) {
        let dismissedAt = Fixture.now.addingTimeInterval(-closedAgo)

        #expect(PolymarketFastTradingBanner.DismissibleKind.extend.isDismissed(dismissedAt: dismissedAt, now: Fixture.now) == isHidden)
    }

    @Test("Nothing is shown while the state is unknown", arguments: [PolymarketFastTradingState.loading, .failed])
    func unknownStateShowsNothing(_ state: PolymarketFastTradingState) {
        #expect(PolymarketFastTradingBanner(state: state, includingForeignSigners: true, isDismissed: { _ in false }) == nil)
    }

    private static func state(showing kind: PolymarketFastTradingBanner.DismissibleKind) -> PolymarketFastTradingState {
        switch kind {
        case .activate:
            return .loaded(Fixture.assess(keys: []))
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

    @Test("A key due for renewal is extended")
    func renewDueRenews() {
        let key = Fixture.key(.local, renewAfter: Fixture.now.addingTimeInterval(-1))

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
}

// MARK: - Helpers

private typealias Fixture = PolymarketSessionKeyFixtures

private extension PolymarketSessionSigner {
    static let unrecorded = PolymarketSessionSigner(
        address: "0xf0e1000000000000000000000000000000000009",
        scopes: ["CLOB"],
        validUntil: Fixture.validUntil
    )

    static func matching(_ key: PolymarketSessionKey) -> PolymarketSessionSigner {
        PolymarketSessionSigner(address: key.address, scopes: key.scopes, validUntil: key.validUntil)
    }
}
