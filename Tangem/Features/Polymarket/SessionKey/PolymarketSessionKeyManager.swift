//
//  PolymarketSessionKeyManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPolymarket

protocol PolymarketSessionKeyManaging {
    func sessionKeys() async throws -> [PolymarketSessionKey]

    func enable(onSigned: @escaping @Sendable () -> Void) async throws -> PolymarketSessionKey

    func authorize(presigned batch: PolymarketRelayedBatch, grant: PolymarketSessionKeyGrant) async throws -> PolymarketSessionKey

    func renew(onSigned: @escaping @Sendable () -> Void) async throws -> PolymarketSessionKey

    func replace(
        previousSessionKeyAddress: String,
        revokesPrevious: Bool,
        onSigned: @escaping @Sendable () -> Void
    ) async throws -> PolymarketSessionKey

    func revoke(sessionKeyAddress: String) async throws -> PolymarketSessionKey

    func setEnabled(_ isEnabled: Bool, sessionKeyAddress: String) async throws -> PolymarketSessionKey
}

enum PolymarketSessionKeyManagerError: Error {
    case operationInProgress
    case unparseableNonce(String)
    case unsettled(PolymarketSessionKey)
    case authorizationFailed(PolymarketSessionKey)
    case revocationFailed(PolymarketSessionKey)
    case missingSessionKey
}

actor CommonPolymarketSessionKeyManager {
    private let userWalletId: UserWalletId
    private let keyStore: PolymarketSessionKeyStore
    private let deviceIdProvider: PolymarketDeviceIdProviding
    private let deviceName: String
    private let depositWalletResolver: PolymarketDepositWalletResolver
    private let relayerService: PolymarketRelayerService
    private let signer: PolymarketBatchesSigning
    private let sessionKeyService: PolymarketSessionKeyService
    private let ownerCredentials: PolymarketOwnerCredentialsObtaining
    private let signingRouter: PolymarketOrderSigningRouting
    private let serverClock: PolymarketServerClock
    private let pollDelayProvider: PollDelayProvider

    private let operationGate: PolymarketWalletOperationGate

    init(
        userWalletId: UserWalletId,
        keyStore: PolymarketSessionKeyStore,
        deviceIdProvider: PolymarketDeviceIdProviding,
        deviceName: String,
        depositWalletResolver: PolymarketDepositWalletResolver,
        relayerService: PolymarketRelayerService,
        signer: PolymarketBatchesSigning,
        sessionKeyService: PolymarketSessionKeyService,
        ownerCredentials: PolymarketOwnerCredentialsObtaining,
        signingRouter: PolymarketOrderSigningRouting,
        serverClock: PolymarketServerClock,
        operationGate: PolymarketWalletOperationGate = .shared,
        pollDelayProvider: PollDelayProvider = TaskSleepPollDelayProvider()
    ) {
        self.userWalletId = userWalletId
        self.operationGate = operationGate
        self.keyStore = keyStore
        self.deviceIdProvider = deviceIdProvider
        self.deviceName = String(deviceName.prefix(Constants.deviceNameLimit))
        self.depositWalletResolver = depositWalletResolver
        self.relayerService = relayerService
        self.signer = signer
        self.sessionKeyService = sessionKeyService
        self.ownerCredentials = ownerCredentials
        self.signingRouter = signingRouter
        self.serverClock = serverClock
        self.pollDelayProvider = pollDelayProvider
    }
}

// MARK: - PolymarketSessionKeyManaging protocol conformance

extension CommonPolymarketSessionKeyManager: PolymarketSessionKeyManaging {
    func sessionKeys() async throws -> [PolymarketSessionKey] {
        try await sessionKeyService.sessionKeys()
    }

    func enable(onSigned: @escaping @Sendable () -> Void) async throws -> PolymarketSessionKey {
        try await exclusively {
            let deviceId = try deviceIdProvider.deviceId()
            let addresses = try await depositWalletResolver.resolve()
            let sessionKeyAddress = try keyStore.heldAddress(for: userWalletId) ?? keyStore.generateKey(for: userWalletId)
            let nonce = try await relayerService.walletNonce(ownerAddress: addresses.owner)

            let authorization = try makeAuthorizationBatch(
                sessionKeyAddress: sessionKeyAddress,
                addresses: addresses,
                nonce: nonce,
                deadlineOffset: Constants.deadlineOffset
            )

            let signed = try await sign([authorization.unsigned], ownerAddress: addresses.owner, onSigned: onSigned)

            guard let batch = signed.first else {
                throw PolymarketSigningError.unknown
            }

            return try await authorize(batch: batch, grant: authorization.grant, deviceId: deviceId)
        }
    }

    func authorize(presigned batch: PolymarketRelayedBatch, grant: PolymarketSessionKeyGrant) async throws -> PolymarketSessionKey {
        try await exclusively {
            try await authorize(batch: batch, grant: grant, deviceId: deviceIdProvider.deviceId())
        }
    }

    func renew(onSigned: @escaping @Sendable () -> Void) async throws -> PolymarketSessionKey {
        try await exclusively {
            let deviceId = try deviceIdProvider.deviceId()

            guard let sessionKeyAddress = try keyStore.heldAddress(for: userWalletId) else {
                throw PolymarketSessionKeyManagerError.missingSessionKey
            }

            return try await revokeThenAuthorize(
                revokedAddress: sessionKeyAddress,
                authorizedAddress: sessionKeyAddress,
                deviceId: deviceId,
                onSigned: onSigned
            )
        }
    }

    func replace(
        previousSessionKeyAddress: String,
        revokesPrevious: Bool,
        onSigned: @escaping @Sendable () -> Void
    ) async throws -> PolymarketSessionKey {
        try await exclusively {
            let deviceId = try deviceIdProvider.deviceId()
            let sessionKeyAddress = try keyStore.heldAddress(for: userWalletId) ?? keyStore.generateKey(for: userWalletId)

            if revokesPrevious {
                return try await revokeThenAuthorize(
                    revokedAddress: previousSessionKeyAddress,
                    authorizedAddress: sessionKeyAddress,
                    deviceId: deviceId,
                    onSigned: onSigned
                )
            }

            let addresses = try await depositWalletResolver.resolve()
            let nonce = try await relayerService.walletNonce(ownerAddress: addresses.owner)

            let authorization = try makeAuthorizationBatch(
                sessionKeyAddress: sessionKeyAddress,
                addresses: addresses,
                nonce: nonce,
                deadlineOffset: Constants.deadlineOffset
            )

            let signed = try await sign([authorization.unsigned], ownerAddress: addresses.owner, onSigned: onSigned)

            guard let batch = signed.first else {
                throw PolymarketSigningError.unknown
            }

            return try await authorize(
                batch: batch,
                grant: authorization.grant,
                deviceId: deviceId,
                replacesSessionKeyAddress: previousSessionKeyAddress
            )
        }
    }

    func revoke(sessionKeyAddress: String) async throws -> PolymarketSessionKey {
        try await exclusively {
            let addresses = try await depositWalletResolver.resolve(acceptedStatuses: .deployedOrLater)
            let nonce = try await relayerService.walletNonce(ownerAddress: addresses.owner)

            let revocation = try makeRevocationBatch(
                sessionKeyAddress: sessionKeyAddress,
                addresses: addresses,
                nonce: nonce
            )

            let signed = try await signer.sign([revocation], as: addresses.owner)

            guard let batch = signed.first else {
                throw PolymarketSigningError.unknown
            }

            let submitted = try await submitRevocation(of: sessionKeyAddress, batch: batch)

            await signingRouter.invalidate(sessionKeyAddress: sessionKeyAddress)

            return submitted
        }
    }

    func setEnabled(_ isEnabled: Bool, sessionKeyAddress: String) async throws -> PolymarketSessionKey {
        let sessionKey = try await submit(sessionKeyAddress: sessionKeyAddress, acceptedWhen: { $0.isEnabled == isEnabled }) {
            try await self.sessionKeyService.setEnabled(isEnabled, sessionKeyAddress: sessionKeyAddress)
        }

        await signingRouter.invalidate(sessionKeyAddress: sessionKeyAddress)

        return sessionKey
    }
}

// MARK: - Operations

private extension CommonPolymarketSessionKeyManager {
    func exclusively<T>(_ operation: () async throws -> T) async throws -> T {
        try await operationGate.exclusively(userWalletId, orThrow: PolymarketSessionKeyManagerError.operationInProgress) {
            try await operation()
        }
    }

    func revokeThenAuthorize(
        revokedAddress: String,
        authorizedAddress: String,
        deviceId: String,
        onSigned: @escaping @Sendable () -> Void
    ) async throws -> PolymarketSessionKey {
        let addresses = try await depositWalletResolver.resolve()
        let nonce = try await relayerService.walletNonce(ownerAddress: addresses.owner)

        guard let revocationNonce = Int(nonce) else {
            throw PolymarketSessionKeyManagerError.unparseableNonce(nonce)
        }

        let revocation = try makeRevocationBatch(
            sessionKeyAddress: revokedAddress,
            addresses: addresses,
            nonce: nonce
        )

        let authorization = try makeAuthorizationBatch(
            sessionKeyAddress: authorizedAddress,
            addresses: addresses,
            nonce: String(revocationNonce + 1),
            deadlineOffset: PolymarketSessionKeyAuthorizationBatch.followUpDeadlineOffset
        )

        let signed = try await sign([revocation, authorization.unsigned], ownerAddress: addresses.owner, onSigned: onSigned)

        guard signed.count == 2, let signedRevocation = signed.first, let signedAuthorization = signed.last else {
            throw PolymarketSigningError.unknown
        }

        let revoking = try await submitRevocation(of: revokedAddress, batch: signedRevocation)

        await signingRouter.invalidate(sessionKeyAddress: revokedAddress)

        let revocationSettlement = try await settlement(of: revoking, deadline: signedRevocation.deadline)

        if case .settled(let revoked) = revocationSettlement, revoked.status != .revoked {
            throw PolymarketSessionKeyManagerError.revocationFailed(revoked)
        }

        return try await authorize(batch: signedAuthorization, grant: authorization.grant, deviceId: deviceId)
    }

    func sign(
        _ batches: [PolymarketRelayedBatch.Unsigned],
        ownerAddress: String,
        onSigned: @Sendable () -> Void
    ) async throws -> [PolymarketRelayedBatch] {
        let ownerAuthTimestamp = ownerCredentials.hasCredentials() ? nil : String(Int(serverClock.now.timeIntervalSince1970))
        let signed = try await signer.sign(batches, ownerAuthTimestamp: ownerAuthTimestamp, as: ownerAddress)

        onSigned()

        if let ownerAuthHeaders = signed.ownerAuthHeaders {
            await ownerCredentials.obtain(authHeaders: ownerAuthHeaders)
        }

        return signed.batches
    }

    func authorize(
        batch: PolymarketRelayedBatch,
        grant: PolymarketSessionKeyGrant,
        deviceId: String,
        replacesSessionKeyAddress: String? = nil
    ) async throws -> PolymarketSessionKey {
        let authorization = try PolymarketSessionKeyAuthorization(
            batch: batch,
            grant: grant,
            deviceId: deviceId,
            deviceName: deviceName,
            replacesSessionKeyAddress: replacesSessionKeyAddress
        )

        let submitted = try await submit(sessionKeyAddress: grant.sessionKeyAddress, acceptedWhen: { $0.showsAuthorization(of: grant) }) {
            try await self.sessionKeyService.authorize(authorization)
        }

        switch try await settlement(of: submitted, deadline: batch.deadline) {
        case .settled(let sessionKey) where sessionKey.status == .active:
            await signingRouter.invalidate(sessionKeyAddress: grant.sessionKeyAddress)
            try await awaitReadiness()

            return sessionKey
        case .settled(let sessionKey):
            throw PolymarketSessionKeyManagerError.authorizationFailed(sessionKey)
        case .vanished:
            throw PolymarketSessionKeyManagerError.authorizationFailed(submitted)
        }
    }

    func submitRevocation(of sessionKeyAddress: String, batch: PolymarketRelayedBatch) async throws -> PolymarketSessionKey {
        let revocation = try PolymarketSessionKeyRevocation(batch: batch, sessionKeyAddress: sessionKeyAddress)

        return try await submit(sessionKeyAddress: sessionKeyAddress, acceptedWhen: \.showsRevocation) {
            try await self.sessionKeyService.revoke(revocation)
        }
    }

    func submit(
        sessionKeyAddress: String,
        acceptedWhen isAccepted: (PolymarketSessionKey) -> Bool,
        _ request: () async throws -> PolymarketSessionKey
    ) async throws -> PolymarketSessionKey {
        var attempt = 0

        while true {
            do {
                return try await request()
            } catch let error as PolymarketSessionKeyError where error.isRetryableWithTheSameRequest && attempt < Constants.resubmitAttempts {
                attempt += 1
                PolymarketLogger.warning("A session key request went unanswered, sending the same signed request again")
                try await pollDelayProvider.wait(for: Constants.pollingInterval)
            } catch let error as PolymarketSessionKeyError where attempt > 0 {
                guard let listed = await listedSessionKey(address: sessionKeyAddress), isAccepted(listed) else {
                    throw error
                }

                PolymarketLogger.warning("A resent session key request failed, but the backend already took an earlier copy of it")

                return listed
            }
        }
    }

    func listedSessionKey(address: String) async -> PolymarketSessionKey? {
        do {
            return try await sessionKeyService.sessionKeys().first { $0.address == address }
        } catch {
            PolymarketLogger.warning("Failed to check whether the backend took an earlier copy of a session key request")
            return nil
        }
    }

    func awaitReadiness() async throws {
        for _ in 0 ..< Constants.readinessAttempts {
            await signingRouter.forgetReadiness()

            if case .sessionKey = await signingRouter.route() {
                return
            }

            try await pollDelayProvider.wait(for: Constants.pollingInterval)
        }

        PolymarketLogger.warning("The session key is active but the exchange does not list it yet, orders stay on the owner key")
    }
}

// MARK: - Settling

private extension CommonPolymarketSessionKeyManager {
    enum Settlement {
        case settled(PolymarketSessionKey)
        case vanished
    }

    func settlement(of sessionKey: PolymarketSessionKey, deadline: String) async throws -> Settlement {
        let waitingLimit = settlingLimit(deadline: deadline)
        var latest = sessionKey
        var misses = 0

        while latest.status.isSettling {
            guard serverClock.now < waitingLimit else {
                throw PolymarketSessionKeyManagerError.unsettled(latest)
            }

            try await pollDelayProvider.wait(for: Constants.pollingInterval)

            do {
                if let listed = try await sessionKeyService.sessionKeys().first(where: { $0.address == sessionKey.address }) {
                    latest = listed
                    misses = 0
                } else if misses < PolymarketSessionKey.settlingMissTolerance {
                    misses += 1
                } else {
                    return .vanished
                }
            } catch where error.isRetryableWithTheSameRequest {
                PolymarketLogger.warning("A session key status request went unanswered, still waiting")
            }
        }

        return .settled(latest)
    }

    func settlingLimit(deadline: String) -> Date {
        let executableUntil = TimeInterval(deadline).map(Date.init(timeIntervalSince1970:))
            ?? serverClock.now.addingTimeInterval(TimeInterval(Constants.deadlineOffset))

        return executableUntil.addingTimeInterval(Constants.settlingGrace)
    }
}

// MARK: - Batches

private extension CommonPolymarketSessionKeyManager {
    func makeAuthorizationBatch(
        sessionKeyAddress: String,
        addresses: PolymarketDepositWalletAddresses,
        nonce: String,
        deadlineOffset: Int
    ) throws -> PolymarketSessionKeyAuthorizationBatch {
        try PolymarketSessionKeyAuthorizationBatch(
            sessionKeyAddress: sessionKeyAddress,
            depositWalletAddress: addresses.depositWallet,
            nonce: nonce,
            now: serverClock.now,
            deadlineOffset: deadlineOffset
        )
    }

    func makeRevocationBatch(
        sessionKeyAddress: String,
        addresses: PolymarketDepositWalletAddresses,
        nonce: String
    ) throws -> PolymarketRelayedBatch.Unsigned {
        let call = try PolymarketSessionKeyCalls.revoke(
            sessionKeyAddress: sessionKeyAddress,
            depositWalletAddress: addresses.depositWallet
        )

        return PolymarketRelayedBatch.Unsigned(
            depositWalletAddress: addresses.depositWallet,
            nonce: nonce,
            deadline: makeDeadline(offset: Constants.deadlineOffset),
            calls: [call]
        )
    }

    func makeDeadline(offset: Int) -> String {
        String(Int(serverClock.now.timeIntervalSince1970) + offset)
    }

    enum Constants {
        static let deadlineOffset = 600
        static let pollingInterval: TimeInterval = 3
        static let settlingGrace: TimeInterval = 60
        static let readinessAttempts = 10
        static let resubmitAttempts = 3
        static let deviceNameLimit = 64
        static let validityTolerance: TimeInterval = 60
    }
}

// MARK: - Authorization batch

struct PolymarketSessionKeyAuthorizationBatch {
    static let followUpDeadlineOffset = 1200

    let unsigned: PolymarketRelayedBatch.Unsigned
    let grant: PolymarketSessionKeyGrant

    init(sessionKeyAddress: String, depositWalletAddress: String, nonce: String, now: Date, deadlineOffset: Int) throws {
        grant = try PolymarketSessionKeyCalls.authorize(
            sessionKeyAddress: sessionKeyAddress,
            depositWalletAddress: depositWalletAddress,
            now: now
        )

        unsigned = PolymarketRelayedBatch.Unsigned(
            depositWalletAddress: depositWalletAddress,
            nonce: nonce,
            deadline: String(Int(now.timeIntervalSince1970) + deadlineOffset),
            calls: [grant.call]
        )
    }
}

// MARK: - Settling misses

extension PolymarketSessionKey {
    static let settlingMissTolerance = 3
}

// MARK: - Accepted requests

private extension PolymarketSessionKey {
    func showsAuthorization(of grant: PolymarketSessionKeyGrant) -> Bool {
        guard status == .pending || status == .active, let validUntil else {
            return false
        }

        return abs(validUntil.timeIntervalSince(grant.validUntil)) <= CommonPolymarketSessionKeyManager.Constants.validityTolerance
    }

    var showsRevocation: Bool {
        status == .revoking || status == .revoked
    }
}
