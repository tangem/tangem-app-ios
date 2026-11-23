//
//  PolymarketFastTradingDoubles.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemPolymarket
import TangemSdk
@testable import Tangem

@MainActor
final class PolymarketSessionKeySigningAvailabilityStub: PolymarketSessionKeySigningAvailability {
    nonisolated static let session = PolymarketSessionCredentials(
        sessionKeyAddress: PolymarketSessionKeyFixtures.localAddress,
        credentials: PolymarketL2Credentials(apiKey: "session", secret: "c2VjcmV0", passphrase: "phrase")
    )

    private(set) var isAvailable: Bool
    private(set) var readinessChecks = 0
    let availableUntil: Date?

    var readiness: PolymarketOrderSigningRoute

    private let subject: CurrentValueSubject<Bool, Never>
    private let readinessGate: TestGate?

    init(
        isAvailable: Bool,
        availableUntil: Date? = nil,
        readiness: PolymarketOrderSigningRoute? = nil,
        readinessGate: TestGate? = nil
    ) {
        self.isAvailable = isAvailable
        self.availableUntil = availableUntil
        self.readiness = readiness ?? (isAvailable ? .sessionKey(Self.session) : .ownerKey)
        self.readinessGate = readinessGate
        subject = CurrentValueSubject(isAvailable)
    }

    var isAvailablePublisher: AnyPublisher<Bool, Never> {
        subject.eraseToAnyPublisher()
    }

    func publish(_ isAvailable: Bool) {
        self.isAvailable = isAvailable
        subject.send(isAvailable)
    }

    func runOut() {
        isAvailable = false
    }

    func refresh() async {}

    func checkReadiness() async -> PolymarketOrderSigningRoute {
        readinessChecks += 1
        await readinessGate?.wait()
        return readiness
    }
}

enum PolymarketSessionKeyFixtures {
    static let validity: TimeInterval = 180 * 24 * 60 * 60
    static let now = Date(timeIntervalSince1970: 1_789_430_400)
    static let hour: TimeInterval = 60 * 60
    static let day: TimeInterval = 24 * hour
    static let validUntil = now.addingTimeInterval(validity)
    static let batchExecutionWindow: TimeInterval = 30 * 60
    static let plainBatchExecutionWindow: TimeInterval = 11 * 60
    static let deviceId = "this-device"
    static let deviceName = "iPhone"
    static let thisDeviceName = "iPhone 16 Air"
    static let localAddress = "0x5e55000000000000000000000000000000000001"

    enum Owner {
        case local
        case previous
        case otherDevice

        var address: String {
            switch self {
            case .local:
                PolymarketSessionKeyFixtures.localAddress
            case .previous:
                "0x5e55000000000000000000000000000000000002"
            case .otherDevice:
                "0x5e55000000000000000000000000000000000003"
            }
        }

        var deviceId: String {
            switch self {
            case .local, .previous:
                PolymarketSessionKeyFixtures.deviceId
            case .otherDevice:
                "other-device"
            }
        }
    }

    static func key(
        _ owner: Owner = .local,
        status: PolymarketSessionKey.Status = .active,
        isEnabled: Bool = true,
        validUntil: Date? = PolymarketSessionKeyFixtures.validUntil,
        authorizedAt: Date? = now.addingTimeInterval(-day),
        createdAt: Date? = nil
    ) -> PolymarketSessionKey {
        PolymarketSessionKey(
            address: owner.address,
            deviceId: owner.deviceId,
            deviceName: deviceName,
            isEnabled: isEnabled,
            status: status,
            scopes: ["CLOB"],
            validUntil: validUntil,
            authorizedAt: authorizedAt,
            createdAt: createdAt ?? (status == .pending ? now.addingTimeInterval(-hour / 60) : authorizedAt)
        )
    }

    static func assess(
        keys: [PolymarketSessionKey],
        signers: [PolymarketSessionSigner]? = [],
        localAddress: String? = PolymarketSessionKeyFixtures.localAddress,
        operations: [PolymarketFastTradingOperation] = [],
        isLocalKeyRefused: Bool = false,
        revokingSince: [String: Date] = [:]
    ) -> PolymarketFastTradingAssessment {
        PolymarketFastTradingAssessment(
            snapshot: PolymarketFastTradingSnapshot(
                sessionKeys: keys,
                localKeyAddress: localAddress,
                deviceId: deviceId,
                signers: signers,
                now: now,
                operations: operations,
                isLocalKeyRefused: isLocalKeyRefused,
                revokingSince: revokingSince
            )
        )
    }
}

extension PolymarketSessionSigner {
    static func matching(_ key: PolymarketSessionKey) -> PolymarketSessionSigner {
        PolymarketSessionSigner(address: key.address, scopes: key.scopes, validUntil: key.validUntil)
    }
}

struct PolymarketDeviceIdProviderStub: PolymarketDeviceIdProviding {
    struct ReadError: Error {}

    var isReadable = true

    func deviceId() throws -> String {
        guard isReadable else {
            throw ReadError()
        }

        return PolymarketSessionKeyFixtures.deviceId
    }
}

struct PolymarketHeldCall {
    let reached = TestGate()
    let release = TestGate()

    func pass() async {
        reached.open()
        await release.wait()
    }
}

final class PolymarketSessionKeyStoreSpy: PolymarketSessionKeyStore, Sendable {
    struct ReadError: Error {}

    static let generatedAddress = "0x5e55000000000000000000000000000000000003"

    static func signature(for hash: Data) -> String {
        "0x" + hash.hexString.lowercased() + "1b"
    }

    private let state: OSAllocatedUnfairLock<State>

    init(heldAddresses: [Result<String?, Error>]) {
        state = OSAllocatedUnfairLock(initialState: State(heldAddresses: heldAddresses))
    }

    convenience init(heldAddress: String?) {
        self.init(heldAddresses: [.success(heldAddress)])
    }

    var generatedKeys: Int {
        state.withLock { $0.generatedKeys }
    }

    func heldAddress(for userWalletId: UserWalletId) throws -> String? {
        let result = state.withLock { state in
            state.heldAddresses.count > 1 ? state.heldAddresses.removeFirst() : (state.heldAddresses.first ?? .success(nil))
        }

        return try result.get()
    }

    func generateKey(for userWalletId: UserWalletId) throws -> String {
        state.withLock { $0.generatedKeys += 1 }

        return Self.generatedAddress
    }

    func sign(hash: Data, for userWalletId: UserWalletId) throws -> String {
        Self.signature(for: hash)
    }

    func deleteKey(for userWalletId: UserWalletId) throws {}

    private struct State {
        var heldAddresses: [Result<String?, Error>]
        var generatedKeys = 0
    }
}

@MainActor
final class PolymarketFastTradingServiceSpy: PolymarketFastTradingServicing {
    let refreshes = TestSignal<Void>()

    private(set) var dismissedBanners: [PolymarketFastTradingBanner] = []
    private(set) var revoked: [String] = []
    private(set) var isWorkCancelled = false

    private let stateSubject: CurrentValueSubject<PolymarketFastTradingState, Never>

    init(state: PolymarketFastTradingState = .loading) {
        stateSubject = CurrentValueSubject(state)
    }

    var state: PolymarketFastTradingState {
        stateSubject.value
    }

    var statePublisher: AnyPublisher<PolymarketFastTradingState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var bannerDismissalsPublisher: AnyPublisher<PolymarketFastTradingBanner.DismissalDates, Never> {
        Just([:]).eraseToAnyPublisher()
    }

    var failurePublisher: AnyPublisher<PolymarketFastTradingFailure, Never> {
        .empty
    }

    var revocationPublisher: AnyPublisher<PolymarketFastTradingRevocation, Never> {
        .empty
    }

    func refresh() async {
        refreshes.send()
    }

    func cancelWork() {
        isWorkCancelled = true
    }

    func dismissBanner(_ banner: PolymarketFastTradingBanner) {
        dismissedBanners.append(banner)
    }

    func authorize(_ authorization: PolymarketFastTradingAuthorization) async throws {}

    func authorize(presigned batch: PolymarketRelayedBatch, grant: PolymarketSessionKeyGrant) async throws {}

    func revoke(sessionKeyAddress: String) async throws {
        revoked.append(sessionKeyAddress)
    }

    func setEnabled(_ isEnabled: Bool, sessionKeyAddress: String) async throws {}

    func reportFailure(_ failure: PolymarketFastTradingFailure) {}
}

final class PolymarketOrderSigningRouterSpy: PolymarketOrderSigningRouting, Sendable {
    private let state: OSAllocatedUnfairLock<State>

    init(refusals: [String: PolymarketOrderSigningRefusal] = [:]) {
        state = OSAllocatedUnfairLock(initialState: State(refusals: refusals))
    }

    var invalidated: [String] {
        state.withLock { $0.invalidated }
    }

    var refusalsPublisher: AnyPublisher<Void, Never> {
        .empty
    }

    func route() async -> PolymarketOrderSigningRoute {
        .ownerKey
    }

    func reportRefused(sessionKeyAddress: String) async {
        state.withLock { $0.refusals[sessionKeyAddress] = PolymarketOrderSigningRefusal(refusedAt: PolymarketSessionKeyFixtures.now, routedOn: nil) }
    }

    func invalidate(sessionKeyAddress: String) async {
        state.withLock { state in
            state.refusals[sessionKeyAddress] = nil
            state.invalidated.append(sessionKeyAddress)
        }
    }

    func forgetReadiness() async {}

    func refusal(of sessionKeyAddress: String) -> PolymarketOrderSigningRefusal? {
        state.withLock { $0.refusals[sessionKeyAddress] }
    }

    private struct State {
        var refusals: [String: PolymarketOrderSigningRefusal]
        var invalidated: [String] = []
    }
}
