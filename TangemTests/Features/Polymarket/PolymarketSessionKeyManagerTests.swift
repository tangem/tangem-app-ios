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

    @Test("A renewal whose revocation did not go through keeps the signed authorization unsent")
    func failedRevocationStopsRenewal() async throws {
        let service = SessionKeyServiceSpy(afterRevocation: [.active])
        let sut = try makeSUT(service: service)

        await #expect(throws: PolymarketSessionKeyManagerError.self) {
            try await sut.renew()
        }

        #expect(service.authorizations.isEmpty)
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

    @Test("A pending key the backend leaves out of a few reads is still waited for")
    func briefGapKeepsWaiting() async throws {
        let gap = [PolymarketSessionKey.Status?](repeating: nil, count: PolymarketSessionKey.settlingMissTolerance)
        let service = SessionKeyServiceSpy(afterAuthorization: gap + [.active])
        let sut = try makeSUT(service: service)

        let sessionKey = try await sut.enable()

        #expect(sessionKey.status == .active)
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
}

// MARK: - Helpers

private extension PolymarketSessionKeyManagerTests {
    static let now = Date(timeIntervalSince1970: 1_789_430_400)
    static let nowSeconds = Int(now.timeIntervalSince1970)
    static let localAddress = "0x5e55000000000000000000000000000000000001"
    static let previousAddress = "0x5e55000000000000000000000000000000000002"
    static let deviceId = PolymarketSessionKeyFixtures.deviceId
    static let deviceName = "iPhone 16 Pro"

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
        clock: PollingClockSpy = PollingClockSpy()
    ) throws -> CommonPolymarketSessionKeyManager {
        let ownerAddress = PolymarketOwnerAddressProviderStub.ownerAddress
        let depositWalletAddress = try PolymarketDepositWalletDeriver.derive(ownerAddress: ownerAddress)

        return CommonPolymarketSessionKeyManager(
            userWalletId: UserWalletId(value: Data(repeating: 0x03, count: 32)),
            keyStore: keyStore,
            deviceIdProvider: deviceIdProvider,
            deviceName: deviceName,
            depositWalletResolver: PolymarketDepositWalletResolver(
                walletService: PolymarketDepositWalletServiceStub(status: walletStatus, depositWalletAddress: depositWalletAddress),
                ownerAddressProvider: PolymarketOwnerAddressProviderStub(derived: ownerAddress)
            ),
            relayerService: PolymarketRelayerServiceStub(),
            signer: signer,
            sessionKeyService: service,
            ownerCredentials: ownerCredentials,
            signingRouter: router,
            serverClock: PolymarketServerClock(deviceNow: { clock.now }),
            operationGate: operationGate,
            pollDelayProvider: clock
        )
    }

    static func key(address: String, status: PolymarketSessionKey.Status, validityShift: TimeInterval = 0) -> PolymarketSessionKey {
        PolymarketSessionKey(
            address: address,
            deviceId: deviceId,
            deviceName: deviceName,
            isEnabled: true,
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

    init(
        listings: [String: [PolymarketSessionKey.Status?]] = [:],
        listedValidityShift: TimeInterval = 0,
        afterAuthorization: [PolymarketSessionKey.Status?] = [.active],
        afterRevocation: [PolymarketSessionKey.Status?] = [.revoked],
        authorizeFailures: [Failure] = [],
        revokeFailures: [Failure] = []
    ) {
        self.listedValidityShift = listedValidityShift
        state = OSAllocatedUnfairLock(initialState: State(
            listings: listings,
            afterAuthorization: afterAuthorization,
            afterRevocation: afterRevocation,
            authorizeFailures: authorizeFailures,
            revokeFailures: revokeFailures
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
        state.withLock { state in
            state.sessionKeyReads += 1

            return state.listings.keys.sorted().compactMap { address in
                state.nextStatus(of: address).map {
                    PolymarketSessionKeyManagerTests.key(address: address, status: $0, validityShift: listedValidityShift)
                }
            }
        }
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
        PolymarketSessionKeyManagerTests.key(address: sessionKeyAddress, status: .active)
    }

    private struct State {
        var listings: [String: [PolymarketSessionKey.Status?]]
        let afterAuthorization: [PolymarketSessionKey.Status?]
        let afterRevocation: [PolymarketSessionKey.Status?]
        var authorizeFailures: [Failure]
        var revokeFailures: [Failure]
        var authorizations: [PolymarketSessionKeyAuthorization] = []
        var revocations: [PolymarketSessionKeyRevocation] = []
        var events: [Event] = []
        var sessionKeyReads = 0

        mutating func receive(_ event: Event, of address: String) -> PolymarketSessionKeyError? {
            let failure: Failure?

            switch event {
            case .authorize:
                failure = authorizeFailures.isEmpty ? nil : authorizeFailures.removeFirst()
            case .revoke:
                failure = revokeFailures.isEmpty ? nil : revokeFailures.removeFirst()
            }

            if failure?.isTaken ?? true {
                events.append(event)
                listings[address] = event == .authorize ? afterAuthorization : afterRevocation
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
        Empty().eraseToAnyPublisher()
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

    nonisolated func isRefused(sessionKeyAddress: String) -> Bool {
        false
    }
}
