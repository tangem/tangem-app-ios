//
//  PolymarketOrderSigningRouteTests.swift
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

@Suite("Polymarket order signing route", .timeLimit(.minutes(1)))
struct PolymarketOrderSigningRouterTests {
    @Test("A session key the exchange lists for trading signs the order instead of the owner key")
    func registeredKeySignsTheOrder() async {
        let fixture = RouterFixture(signers: [.usable])

        #expect(await fixture.sut.route() == .sessionKey(RouterFixture.session))
    }

    @Test("A wallet that cannot use session keys always signs with the owner key")
    func ineligibleWalletUsesTheOwnerKey() async {
        let fixture = RouterFixture(isEligible: false, signers: [.usable])

        #expect(await fixture.sut.route() == .ownerKey)
        #expect(fixture.clob.sessionSignerReads == 0)
    }

    @Test("A device without a session key signs with the owner key and asks the exchange nothing")
    func noKeyUsesTheOwnerKey() async {
        let fixture = RouterFixture(heldAddress: nil, signers: [.usable])

        #expect(await fixture.sut.route() == .ownerKey)
        #expect(fixture.clob.sessionSignerReads == 0)
    }

    @Test(
        "A session key the exchange does not list as usable stays off orders",
        arguments: [
            [PolymarketSessionSigner](),
            [.expiringSoon],
            [.withoutTradingScope],
            [.otherDevice],
        ]
    )
    func unusableKeyUsesTheOwnerKey(_ signers: [PolymarketSessionSigner]) async {
        let fixture = RouterFixture(signers: signers)

        #expect(await fixture.sut.route() == .ownerKey)
    }

    @Test("A session key switched off on the backend stays off orders even while the exchange lists it")
    func disabledKeyUsesTheOwnerKey() async {
        let fixture = RouterFixture(signers: [.usable], backendKeys: [.make(isEnabled: false)])

        #expect(await fixture.sut.route() == .ownerKey)
    }

    @Test("A session key the backend has no active record of stays off orders even while the exchange lists it")
    func unrecordedKeyUsesTheOwnerKey() async {
        let fixture = RouterFixture(signers: [.usable], backendKeys: [])

        #expect(await fixture.sut.route() == .ownerKey)
    }

    @Test(
        "A backend record that is not active or about to expire keeps the session key off orders",
        arguments: [
            PolymarketSessionKey.make(isEnabled: true, status: .pending),
            .make(isEnabled: true, status: .revoking),
            .make(isEnabled: true, status: .revoked),
            .make(isEnabled: true, validUntil: RouterFixture.now.addingTimeInterval(60)),
        ]
    )
    func unusableRecordUsesTheOwnerKey(_ record: PolymarketSessionKey) async {
        let fixture = RouterFixture(signers: [.usable], backendKeys: [record])

        #expect(await fixture.sut.route() == .ownerKey)
    }

    @Test("A refusal is announced so the fast trading state is read again")
    func refusalIsAnnounced() async {
        let fixture = RouterFixture(signers: [.usable])
        var announcements = 0
        let subscription = fixture.sut.refusalsPublisher.sink { announcements += 1 }

        await fixture.sut.reportRefused(sessionKeyAddress: RouterFixture.sessionKeyAddress)

        #expect(announcements == 1)
        subscription.cancel()
    }

    @Test("A session key the exchange refused is not offered again")
    func refusedKeyUsesTheOwnerKey() async {
        let fixture = RouterFixture(signers: [.usable])

        await fixture.sut.reportRefused(sessionKeyAddress: RouterFixture.sessionKeyAddress)

        #expect(await fixture.sut.route() == .ownerKey)
    }

    @Test("A refused session key stays off orders when another key changes")
    func refusalOutlivesAnotherKeyChange() async {
        let fixture = RouterFixture(signers: [.usable])

        await fixture.sut.reportRefused(sessionKeyAddress: RouterFixture.sessionKeyAddress)
        await fixture.sut.invalidate(sessionKeyAddress: PolymarketSessionSigner.otherDevice.address)

        #expect(await fixture.sut.route() == .ownerKey)
    }

    @Test("A refused session key is offered again once it changes")
    func changedKeyIsOfferedAgain() async {
        let fixture = RouterFixture(signers: [.usable])

        await fixture.sut.reportRefused(sessionKeyAddress: RouterFixture.sessionKeyAddress)
        await fixture.sut.invalidate(sessionKeyAddress: RouterFixture.sessionKeyAddress)

        #expect(await fixture.sut.route() == .sessionKey(RouterFixture.session))
    }

    @Test("A confirmed session key is not checked with the exchange before every order")
    func readinessIsRemembered() async {
        let fixture = RouterFixture(signers: [.usable])

        _ = await fixture.sut.route()
        _ = await fixture.sut.route()

        #expect(fixture.clob.sessionSignerReads == 1)
    }

    @Test("A session key whose credentials could not be obtained is not checked again for the next order")
    func credentialsFailureIsRemembered() async {
        let fixture = RouterFixture(signers: [.usable], credentialsError: PolymarketAPIError.http(statusCode: 400, problemDetail: nil))

        #expect(await fixture.sut.route() == .ownerKey)
        #expect(await fixture.sut.route() == .ownerKey)
        #expect(fixture.clob.sessionSignerReads == 1)
    }

    @Test("A forgotten readiness answer is checked with the exchange again")
    func forgottenReadinessIsCheckedAgain() async {
        let fixture = RouterFixture(signers: [])

        _ = await fixture.sut.route()
        await fixture.sut.forgetReadiness()
        _ = await fixture.sut.route()

        #expect(fixture.clob.sessionSignerReads == 2)
    }

    @Test("A session key found not ready is not checked again for the next order until its state changes")
    func notReadyAnswerIsRemembered() async {
        let fixture = RouterFixture(signers: [])

        _ = await fixture.sut.route()
        _ = await fixture.sut.route()
        await fixture.sut.invalidate(sessionKeyAddress: RouterFixture.sessionKeyAddress)
        _ = await fixture.sut.route()

        #expect(fixture.clob.sessionSignerReads == 2)
    }

    @Test("A session key renewed, resumed or authorized again gets its exchange credentials derived again instead of reusing the cached ones")
    func changedKeyDerivesItsCredentialsAgain() async {
        let fixture = RouterFixture(signers: [.usable], derivesCredentials: true)

        _ = await fixture.sut.route()
        _ = await fixture.sut.route()
        await fixture.sut.invalidate(sessionKeyAddress: RouterFixture.sessionKeyAddress)
        _ = await fixture.sut.route()

        #expect(fixture.clob.deriveRequests == 2)
    }

    @Test("A check the network or the server failed leaves the order unrouted and is made again for the next order")
    func failedCheckIsUnverified() async {
        let fixture = RouterFixture(signers: [.usable], signersError: PolymarketAPIError.http(statusCode: 503, problemDetail: nil))

        #expect(await fixture.sut.route() == .unverified)
        #expect(await fixture.sut.route() == .unverified)
        #expect(fixture.clob.sessionSignerReads == 2)
    }

    @Test("A check answered after the session key was paused neither signs the order nor is remembered")
    func pausedCheckIsDiscarded() async {
        let backendRead = PolymarketHeldCall()
        let fixture = RouterFixture(signers: [.usable], backendRead: backendRead)
        let sut = fixture.sut

        let routing = Task { await sut.route() }
        await backendRead.reached.wait()
        await sut.invalidate(sessionKeyAddress: RouterFixture.sessionKeyAddress)
        backendRead.release.open()

        #expect(await routing.value == .ownerKey)
        #expect(await sut.route() == .sessionKey(RouterFixture.session))
        #expect(fixture.clob.sessionSignerReads == 2)
    }

    @Test("A check started before readiness was forgotten neither signs the order nor is remembered")
    func checkBeforeForgettingIsDiscarded() async {
        let backendRead = PolymarketHeldCall()
        let fixture = RouterFixture(signers: [.usable], backendRead: backendRead)
        let sut = fixture.sut

        let routing = Task { await sut.route() }
        await backendRead.reached.wait()
        await sut.forgetReadiness()
        backendRead.release.open()

        #expect(await routing.value == .ownerKey)
        #expect(await sut.route() == .sessionKey(RouterFixture.session))
        #expect(fixture.clob.sessionSignerReads == 2)
    }

    @Test("A confirmed key stops signing orders once it reaches the expiry margin, before its confirmation would run out")
    func confirmationEndsAtTheExpiryMargin() async {
        let signer = PolymarketSessionSigner(
            address: RouterFixture.sessionKeyAddress,
            scopes: ["CLOB"],
            validUntil: RouterFixture.now.addingTimeInterval(PolymarketSessionKey.signingExpiryMargin + 60)
        )
        let fixture = RouterFixture(signers: [signer])

        #expect(await fixture.sut.route() == .sessionKey(RouterFixture.session))

        fixture.advanceClock(by: 61)

        #expect(await fixture.sut.route() == .ownerKey)
    }

    @Test("A refusal that lands while an order is being routed keeps that order off the refused key")
    func refusalDuringRoutingWins() async {
        let credentialsRead = PolymarketHeldCall()
        let fixture = RouterFixture(signers: [.usable], credentialsRead: credentialsRead)
        let sut = fixture.sut

        let routing = Task { await sut.route() }
        await credentialsRead.reached.wait()
        await sut.reportRefused(sessionKeyAddress: RouterFixture.sessionKeyAddress)
        credentialsRead.release.open()

        #expect(await routing.value == .ownerKey)
    }
}

// MARK: - Helpers

private final class RouterFixture {
    static let userWalletId = UserWalletId(value: Data(repeating: 0x02, count: 32))
    static let sessionKeyAddress = "0x5e55000000000000000000000000000000000001"
    static let now = Date(timeIntervalSince1970: 1_789_430_400)
    static let session = PolymarketSessionCredentials(
        sessionKeyAddress: sessionKeyAddress,
        credentials: PolymarketL2Credentials(apiKey: "session", secret: "c2VjcmV0", passphrase: "phrase")
    )

    let clob: PolymarketCLOBServiceStub
    let sut: CommonPolymarketOrderSigningRouter

    private let clock: OSAllocatedUnfairLock<Date>

    init(
        isEligible: Bool = true,
        heldAddress: String? = RouterFixture.sessionKeyAddress,
        signers: [PolymarketSessionSigner],
        signersError: Error? = nil,
        backendKeys: [PolymarketSessionKey]? = nil,
        backendRead: PolymarketHeldCall? = nil,
        credentialsRead: PolymarketHeldCall? = nil,
        credentialsError: Error? = nil,
        derivesCredentials: Bool = false
    ) {
        let signersResult: Result<[PolymarketSessionSigner], Error> = signersError.map { .failure($0) } ?? .success(signers)
        let keyStore = PolymarketSessionKeyStoreSpy(heldAddress: heldAddress)
        let clock = OSAllocatedUnfairLock(initialState: Self.now)
        let now = { clock.withLock { $0 } }

        self.clock = clock

        clob = PolymarketCLOBServiceStub(sessionSignersResult: signersResult)

        let sessionCredentialsProvider: PolymarketSessionCredentialsProviding = derivesCredentials
            ? CommonPolymarketSessionCredentialsProvider(userWalletId: Self.userWalletId, keyStore: keyStore, clobService: clob, now: now)
            : SessionCredentialsStub(session: Self.session, hold: credentialsRead, error: credentialsError)

        sut = CommonPolymarketOrderSigningRouter(
            userWalletId: Self.userWalletId,
            isEligible: isEligible,
            keyStore: keyStore,
            sessionCredentialsProvider: sessionCredentialsProvider,
            clobService: clob,
            sessionKeyService: SessionKeyServiceStub(keys: backendKeys ?? [.make(isEnabled: true)], hold: backendRead),
            credentialsRepository: PolymarketCredentialsRepositoryStub(stored: PolymarketCredentialsRepositoryStub.credentials),
            ownerAddressProvider: PolymarketOwnerAddressProviderStub(derived: PolymarketOwnerAddressProviderStub.ownerAddress),
            now: now
        )
    }

    func advanceClock(by interval: TimeInterval) {
        clock.withLock { $0.addTimeInterval(interval) }
    }
}

private extension PolymarketSessionSigner {
    static let usable = PolymarketSessionSigner(
        address: RouterFixture.sessionKeyAddress,
        scopes: ["CLOB"],
        validUntil: RouterFixture.now.addingTimeInterval(PolymarketSessionKeyFixtures.validity)
    )

    static let expiringSoon = PolymarketSessionSigner(
        address: RouterFixture.sessionKeyAddress,
        scopes: ["CLOB"],
        validUntil: RouterFixture.now.addingTimeInterval(60)
    )

    static let withoutTradingScope = PolymarketSessionSigner(
        address: RouterFixture.sessionKeyAddress,
        scopes: ["COMBOSRFQ"],
        validUntil: RouterFixture.now.addingTimeInterval(PolymarketSessionKeyFixtures.validity)
    )

    static let otherDevice = PolymarketSessionSigner(
        address: "0x01d0000000000000000000000000000000000009",
        scopes: ["CLOB"],
        validUntil: RouterFixture.now.addingTimeInterval(PolymarketSessionKeyFixtures.validity)
    )
}

private extension PolymarketSessionKey {
    static func make(
        isEnabled: Bool,
        status: Status = .active,
        validUntil: Date = RouterFixture.now.addingTimeInterval(PolymarketSessionKeyFixtures.validity)
    ) -> PolymarketSessionKey {
        PolymarketSessionKey(
            address: RouterFixture.sessionKeyAddress,
            deviceId: "device",
            deviceName: "iPhone 16 Pro",
            isEnabled: isEnabled,
            status: status,
            scopes: ["CLOB"],
            validUntil: validUntil,
            renewAfter: nil,
            authorizedAt: RouterFixture.now,
            createdAt: RouterFixture.now
        )
    }
}

// MARK: - Stubs

private struct SessionCredentialsStub: PolymarketSessionCredentialsProviding {
    let session: PolymarketSessionCredentials
    let hold: PolymarketHeldCall?
    var error: Error?

    func credentials() async throws -> PolymarketSessionCredentials {
        await hold?.pass()

        if let error {
            throw error
        }

        return session
    }

    func reset() {}
}

private struct SessionKeyServiceStub: PolymarketSessionKeyService {
    let keys: [PolymarketSessionKey]
    let hold: PolymarketHeldCall?

    func sessionKeys() async throws(PolymarketSessionKeyError) -> [PolymarketSessionKey] {
        await hold?.pass()

        return keys
    }

    func authorize(_ authorization: PolymarketSessionKeyAuthorization) async throws(PolymarketSessionKeyError) -> PolymarketSessionKey {
        throw .cancelled
    }

    func revoke(_ revocation: PolymarketSessionKeyRevocation) async throws(PolymarketSessionKeyError) -> PolymarketSessionKey {
        throw .cancelled
    }

    func setEnabled(_ isEnabled: Bool, sessionKeyAddress: String) async throws(PolymarketSessionKeyError) -> PolymarketSessionKey {
        throw .cancelled
    }
}
