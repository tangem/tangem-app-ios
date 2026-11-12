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

    func repair(onSigned: @escaping @Sendable () -> Void) async throws -> PolymarketSessionKey

    func replace(
        previousSessionKeyAddress: String,
        revokesPrevious: Bool,
        onSigned: @escaping @Sendable () -> Void
    ) async throws -> PolymarketSessionKey

    func revoke(sessionKeyAddress: String) async throws -> PolymarketSessionKey

    func setEnabled(_ isEnabled: Bool, sessionKeyAddress: String) async throws -> PolymarketSessionKey

    func resumableInterruptedAuthorization() async -> PolymarketInterruptedAuthorization?

    func resumeInterruptedAuthorization() async throws -> PolymarketSessionKey
}

enum PolymarketSessionKeyManagerError: Error {
    case operationInProgress
    case unparseableNonce(String)
    case unsettled(PolymarketSessionKey)
    case authorizationFailed(PolymarketSessionKey)
    case revocationFailed(PolymarketSessionKey)
    case missingSessionKey
    case noInterruptedAuthorization
    case nonceSpentElsewhere
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
    private let interruptedAuthorizations: PolymarketInterruptedAuthorizationStore
    private let serverClock: PolymarketServerClock
    private let pollDelayProvider: PollDelayProvider

    private let operationGate: PolymarketWalletOperationGate
    private let operationSlot: PolymarketWalletOperationSlot

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
        interruptedAuthorizations: PolymarketInterruptedAuthorizationStore,
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
        self.interruptedAuthorizations = interruptedAuthorizations
        self.serverClock = serverClock
        self.pollDelayProvider = pollDelayProvider

        operationSlot = PolymarketWalletOperationSlot(
            userWalletId: userWalletId,
            holder: .fastTradingChange,
            gate: operationGate,
            interruptedAuthorizations: interruptedAuthorizations,
            serverClock: serverClock
        )
    }
}

// MARK: - PolymarketSessionKeyManaging protocol conformance

extension CommonPolymarketSessionKeyManager: PolymarketSessionKeyManaging {
    func sessionKeys() async throws -> [PolymarketSessionKey] {
        try await sessionKeyService.sessionKeys()
    }

    func enable(onSigned: @escaping @Sendable () -> Void) async throws -> PolymarketSessionKey {
        try await exclusivelyOnTheNextNonce {
            let deviceId = try deviceIdProvider.deviceId()
            let addresses = try await depositWalletResolver.resolve()
            let sessionKeyAddress = try authorizations.heldOrNewKeyAddress()
            let nonce = try await relayerService.walletNonce(ownerAddress: addresses.owner)

            let authorization = try makeAuthorizationBatch(
                sessionKeyAddress: sessionKeyAddress,
                addresses: addresses,
                nonce: nonce,
                deadlineOffset: PolymarketSessionKeyAuthorizationBatch.deadlineOffset
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
        try await reauthorizeHeldKey(as: .renewal, onSigned: onSigned)
    }

    func repair(onSigned: @escaping @Sendable () -> Void) async throws -> PolymarketSessionKey {
        try await reauthorizeHeldKey(as: .activation, onSigned: onSigned)
    }

    func replace(
        previousSessionKeyAddress: String,
        revokesPrevious: Bool,
        onSigned: @escaping @Sendable () -> Void
    ) async throws -> PolymarketSessionKey {
        try await exclusivelyOnTheNextNonce {
            let deviceId = try deviceIdProvider.deviceId()
            let sessionKeyAddress = try authorizations.heldOrNewKeyAddress()

            if revokesPrevious {
                return try await revokeThenAuthorize(
                    revokedAddress: previousSessionKeyAddress,
                    authorizedAddress: sessionKeyAddress,
                    deviceId: deviceId,
                    purpose: .activation,
                    onSigned: onSigned
                )
            }

            let addresses = try await depositWalletResolver.resolve()
            let nonce = try await relayerService.walletNonce(ownerAddress: addresses.owner)

            let authorization = try makeAuthorizationBatch(
                sessionKeyAddress: sessionKeyAddress,
                addresses: addresses,
                nonce: nonce,
                deadlineOffset: PolymarketSessionKeyAuthorizationBatch.deadlineOffset
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
        try await exclusivelyOnTheNextNonce {
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
        let sessionKey = try await retryingWhileBusy {
            try await submit(recordIn: { $0.decisiveRecord(of: sessionKeyAddress) }, acceptedWhen: { $0.isEnabled == isEnabled }) {
                try await self.sessionKeyService.setEnabled(isEnabled, sessionKeyAddress: sessionKeyAddress)
            }
        }

        await signingRouter.forgetReadiness()

        return sessionKey
    }

    func resumableInterruptedAuthorization() async -> PolymarketInterruptedAuthorization? {
        guard !operationGate.isBusy(userWalletId) else {
            return nil
        }

        return interruptedAuthorization()
    }

    func resumeInterruptedAuthorization() async throws -> PolymarketSessionKey {
        try await exclusively {
            guard let interrupted = interruptedAuthorization() else {
                throw PolymarketSessionKeyManagerError.noInterruptedAuthorization
            }

            return try await keepingWhileExecutable(interrupted) {
                let listed = try await sessionKeyService.sessionKeys()

                if let authorized = listed.record(of: interrupted.grant) {
                    return try await settledInterruptedAuthorization(of: authorized, interrupted: interrupted)
                }

                guard interrupted.isExecutable(at: serverClock.now) else {
                    PolymarketLogger.warning("An interrupted fast trading authorization expired before the backend listed it, dropping it")
                    forget(interrupted)
                    throw PolymarketSessionKeyManagerError.noInterruptedAuthorization
                }

                try await completeInterruptedRevocation(
                    of: interrupted,
                    revoked: listed.revocationRecord(of: interrupted.revokedAddress, at: serverClock.now)
                )

                return try await authorizeInterrupted(interrupted)
            }
        }
    }
}

// MARK: - Operations

private extension CommonPolymarketSessionKeyManager {
    func exclusively<T>(_ operation: () async throws -> T) async throws -> T {
        try await operationGate.exclusively(userWalletId, as: .fastTradingChange, orThrow: { _ in PolymarketSessionKeyManagerError.operationInProgress }) {
            try await operation()
        }
    }

    func exclusivelyOnTheNextNonce<T>(_ operation: () async throws -> T) async throws -> T {
        try await operationSlot.exclusively(
            orThrow: PolymarketSessionKeyManagerError.operationInProgress,
            whileFastTradingChangePends: PolymarketSessionKeyManagerError.operationInProgress
        ) {
            forgetInterruptedAuthorization { !$0.isExecutable(at: serverClock.now) }

            return try await operation()
        }
    }

    func reauthorizeHeldKey(
        as purpose: PolymarketInterruptedAuthorization.Purpose,
        onSigned: @escaping @Sendable () -> Void
    ) async throws -> PolymarketSessionKey {
        try await exclusivelyOnTheNextNonce {
            let deviceId = try deviceIdProvider.deviceId()

            guard let sessionKeyAddress = try keyStore.heldAddress(for: userWalletId) else {
                throw PolymarketSessionKeyManagerError.missingSessionKey
            }

            return try await revokeThenAuthorize(
                revokedAddress: sessionKeyAddress,
                authorizedAddress: sessionKeyAddress,
                deviceId: deviceId,
                purpose: purpose,
                onSigned: onSigned
            )
        }
    }

    func revokeThenAuthorize(
        revokedAddress: String,
        authorizedAddress: String,
        deviceId: String,
        purpose: PolymarketInterruptedAuthorization.Purpose,
        onSigned: @escaping @Sendable () -> Void
    ) async throws -> PolymarketSessionKey {
        let addresses = try await depositWalletResolver.resolve()
        let nonce = try await relayerService.walletNonce(ownerAddress: addresses.owner)

        let revocation = try makeRevocationBatch(
            sessionKeyAddress: revokedAddress,
            addresses: addresses,
            nonce: nonce
        )

        let authorization = try makeAuthorizationBatch(
            sessionKeyAddress: authorizedAddress,
            addresses: addresses,
            nonce: PolymarketSessionKeyAuthorizationBatch.nonce(following: nonce),
            deadlineOffset: PolymarketSessionKeyAuthorizationBatch.followUpDeadlineOffset
        )

        let signed = try await sign([revocation, authorization.unsigned], ownerAddress: addresses.owner, onSigned: onSigned)

        guard signed.count == 2, let signedRevocation = signed.first, let signedAuthorization = signed.last else {
            throw PolymarketSigningError.unknown
        }

        let interrupted = PolymarketInterruptedAuthorization(
            revokedAddress: revokedAddress,
            revocation: signedRevocation,
            batch: signedAuthorization,
            grant: authorization.grant,
            deviceId: deviceId,
            purpose: purpose
        )

        try keep(interrupted)

        return try await keepingWhileExecutable(interrupted) {
            try await revokeInterrupted(interrupted)

            return try await authorizeInterrupted(interrupted)
        }
    }

    func awaitRevocation(of revoking: PolymarketSessionKey) async throws {
        let settled = try await revocationSettlement(of: revoking)

        if case .settled(let revoked) = settled, revoked.status != .revoked {
            throw PolymarketSessionKeyManagerError.revocationFailed(revoked)
        }
    }

    func confirmRevocation(of revoking: PolymarketSessionKey) async throws {
        guard case .settled(let revoked) = try await revocationSettlement(of: revoking) else {
            PolymarketLogger.warning("A revoking key the backend stopped listing does not confirm the revocation of an interrupted renewal")
            throw PolymarketSessionKeyManagerError.revocationFailed(revoking)
        }

        guard revoked.status == .revoked else {
            throw PolymarketSessionKeyManagerError.revocationFailed(revoked)
        }
    }

    func revocationSettlement(of revoking: PolymarketSessionKey) async throws -> Settlement {
        try await settlement(of: revoking) { listed in
            listed.revocationRecord(of: revoking.address, at: serverClock.now)
        }
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
        let submitted = try await submitAuthorization(
            batch: batch,
            grant: grant,
            deviceId: deviceId,
            replacesSessionKeyAddress: replacesSessionKeyAddress
        )

        return try await settledAuthorization(of: submitted, grant: grant)
    }

    func submitAuthorization(
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

        return try await submit(recordIn: { $0.record(of: grant) }, acceptedWhen: { $0.showsAuthorization(of: grant) }) {
            try await self.sessionKeyService.authorize(authorization)
        }
    }

    func settledAuthorization(
        of submitted: PolymarketSessionKey,
        grant: PolymarketSessionKeyGrant
    ) async throws -> PolymarketSessionKey {
        let settled = try await settlement(of: submitted) { listed in
            listed.record(of: grant)
        }

        switch settled {
        case .settled(let authorized) where authorized.status == .active:
            await signingRouter.invalidate(sessionKeyAddress: grant.sessionKeyAddress)
            forgetInterruptedAuthorization(of: grant)

            if authorized.isEnabled {
                try await awaitReadiness()
            }

            return authorized
        case .settled(let sessionKey):
            throw PolymarketSessionKeyManagerError.authorizationFailed(sessionKey)
        case .vanished:
            throw PolymarketSessionKeyManagerError.authorizationFailed(submitted)
        }
    }

    func submitRevocation(of sessionKeyAddress: String, batch: PolymarketRelayedBatch) async throws -> PolymarketSessionKey {
        let revocation = try PolymarketSessionKeyRevocation(batch: batch, sessionKeyAddress: sessionKeyAddress)

        return try await submit(recordIn: { $0.revocationRecord(of: sessionKeyAddress, at: serverClock.now) }, acceptedWhen: \.showsRevocation) {
            try await self.sessionKeyService.revoke(revocation)
        }
    }

    func submit(
        recordIn pick: ([PolymarketSessionKey]) -> PolymarketSessionKey?,
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
                guard let listed = await listedSessionKey(recordIn: pick), isAccepted(listed) else {
                    throw error
                }

                PolymarketLogger.warning("A resent session key request failed, but the backend already took an earlier copy of it")

                return listed
            }
        }
    }

    func retryingWhileBusy(_ request: () async throws -> PolymarketSessionKey) async throws -> PolymarketSessionKey {
        var attempt = 0

        while true {
            do {
                return try await request()
            } catch PolymarketSessionKeyError.refused(_, .busy, _) where attempt < Constants.busyRetryAttempts {
                attempt += 1
                PolymarketLogger.warning("The backend is busy with the session key, sending the same switch again")
                try await pollDelayProvider.wait(for: Constants.busyRetryDelay)
            }
        }
    }

    func listedSessionKey(recordIn pick: ([PolymarketSessionKey]) -> PolymarketSessionKey?) async -> PolymarketSessionKey? {
        do {
            return try await pick(sessionKeyService.sessionKeys())
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

// MARK: - Interrupted authorization

private extension CommonPolymarketSessionKeyManager {
    func keep(_ interrupted: PolymarketInterruptedAuthorization) throws {
        do {
            try save(interrupted)
        } catch {
            PolymarketLogger.error("Failed to keep the signed fast trading authorization for a resume, nothing is sent", error: error)
            throw error
        }
    }

    func save(_ interrupted: PolymarketInterruptedAuthorization) throws {
        try Task.checkCancellation()
        try interruptedAuthorizations.save(interrupted, for: userWalletId)
    }

    func interruptedAuthorization() -> PolymarketInterruptedAuthorization? {
        do {
            return try interruptedAuthorizations.load(for: userWalletId)
        } catch is DecodingError {
            PolymarketLogger.warning("An interrupted fast trading authorization could not be decoded, dropping it")
            deleteInterruptedAuthorization()
            return nil
        } catch {
            PolymarketLogger.error("Failed to read an interrupted fast trading authorization", error: error)
            return nil
        }
    }

    func keepingWhileExecutable(
        _ interrupted: PolymarketInterruptedAuthorization,
        _ operation: () async throws -> PolymarketSessionKey
    ) async throws -> PolymarketSessionKey {
        do {
            return try await operation()
        } catch {
            if Self.endsTheInterruptedAuthorization(error) {
                forget(interrupted)
            }

            throw error
        }
    }

    func forgettingIfRefused(
        _ interrupted: PolymarketInterruptedAuthorization,
        _ submit: () async throws -> PolymarketSessionKey
    ) async throws -> PolymarketSessionKey {
        do {
            return try await submit()
        } catch {
            if Self.isFinalRefusal(error) {
                forget(interrupted)
            }

            throw error
        }
    }

    func revokeInterrupted(_ interrupted: PolymarketInterruptedAuthorization) async throws {
        let revoking = try await forgettingIfRefused(interrupted) {
            try await submitRevocation(of: interrupted.revokedAddress, batch: interrupted.revocation)
        }

        await signingRouter.invalidate(sessionKeyAddress: interrupted.revokedAddress)

        try await awaitRevocation(of: revoking)
    }

    func completeInterruptedRevocation(of interrupted: PolymarketInterruptedAuthorization, revoked: PolymarketSessionKey?) async throws {
        let walletNonce = try await relayerService.walletNonce(ownerAddress: interrupted.batch.ownerAddress)
        let revoking = revoked?.status == .revoking ? revoked : nil

        switch interrupted.stage(atWalletNonce: walletNonce) {
        case .revocationUnused:
            guard interrupted.isRevocationExecutable(at: serverClock.now) else {
                PolymarketLogger.warning("The revocation of an interrupted renewal can no longer run, dropping its authorization")
                forget(interrupted)
                throw PolymarketSessionKeyManagerError.noInterruptedAuthorization
            }

            if let revoking {
                try await awaitRevocation(of: revoking)
                return
            }

            try await revokeInterrupted(interrupted)
        case .revocationExecuted:
            guard let revoked, revoked.showsRevocation else {
                PolymarketLogger.warning("Another operation spent the wallet nonce of an interrupted revocation, dropping its authorization")
                forget(interrupted)
                throw PolymarketSessionKeyManagerError.nonceSpentElsewhere
            }

            if let revoking {
                try await confirmRevocation(of: revoking)
            }
        case .moved:
            PolymarketLogger.warning("The wallet nonce matches neither the revocation nor the authorization of an interrupted renewal, dropping it")
            forget(interrupted)
            throw PolymarketSessionKeyManagerError.noInterruptedAuthorization
        }
    }

    func authorizeInterrupted(_ interrupted: PolymarketInterruptedAuthorization) async throws -> PolymarketSessionKey {
        let submitted = try await forgettingIfRefused(interrupted) {
            try await submitAuthorization(batch: interrupted.batch, grant: interrupted.grant, deviceId: interrupted.deviceId)
        }

        return try await settledAuthorization(
            of: submitted,
            grant: interrupted.grant
        )
    }

    func settledInterruptedAuthorization(
        of authorized: PolymarketSessionKey,
        interrupted: PolymarketInterruptedAuthorization
    ) async throws -> PolymarketSessionKey {
        switch authorized.status {
        case .pending, .active:
            return try await settledAuthorization(
                of: authorized,
                grant: interrupted.grant
            )
        case .failed, .expired, .unknown:
            throw PolymarketSessionKeyManagerError.authorizationFailed(authorized)
        case .revoking, .revoked:
            PolymarketLogger.warning("An interrupted fast trading authorization went through and was revoked since, dropping it")
            forget(interrupted)
            throw PolymarketSessionKeyManagerError.noInterruptedAuthorization
        }
    }

    static func endsTheInterruptedAuthorization(_ error: Error) -> Bool {
        switch error {
        case PolymarketSessionKeyManagerError.authorizationFailed, PolymarketSessionKeyManagerError.revocationFailed:
            true
        default:
            false
        }
    }

    static func isFinalRefusal(_ error: Error) -> Bool {
        switch error {
        case let error as PolymarketSessionKeyError where error.isBusyRefusal:
            false
        case PolymarketSessionKeyError.refused, is PolymarketSessionKeyRequestError:
            true
        default:
            false
        }
    }

    func forget(_ interrupted: PolymarketInterruptedAuthorization) {
        forgetInterruptedAuthorization { $0.batch == interrupted.batch }
    }

    func forgetInterruptedAuthorization(of grant: PolymarketSessionKeyGrant) {
        forgetInterruptedAuthorization { $0.isOf(grant) }
    }

    func forgetInterruptedAuthorization(where isForgotten: (PolymarketInterruptedAuthorization) -> Bool) {
        let kept: PolymarketInterruptedAuthorization?

        do {
            kept = try interruptedAuthorizations.load(for: userWalletId)
        } catch {
            PolymarketLogger.warning("Failed to read the interrupted fast trading authorization to forget")
            return
        }

        guard let kept, isForgotten(kept) else {
            return
        }

        deleteInterruptedAuthorization()
    }

    func deleteInterruptedAuthorization() {
        do {
            try interruptedAuthorizations.delete(for: userWalletId)
        } catch {
            PolymarketLogger.warning("Failed to forget an interrupted fast trading authorization")
        }
    }
}

// MARK: - Settling

private extension CommonPolymarketSessionKeyManager {
    enum Settlement {
        case settled(PolymarketSessionKey)
        case vanished
    }

    func settlement(
        of sessionKey: PolymarketSessionKey,
        recordIn pick: ([PolymarketSessionKey]) -> PolymarketSessionKey?
    ) async throws -> Settlement {
        let waitingLimit = serverClock.now.addingTimeInterval(PolymarketSessionKey.backendHoldLimit + PolymarketSessionKey.settlingGrace)
        var latest = sessionKey
        var misses = 0

        while latest.status.isSettling {
            guard serverClock.now < waitingLimit else {
                throw PolymarketSessionKeyManagerError.unsettled(latest)
            }

            try await pollDelayProvider.wait(for: Constants.pollingInterval)

            do {
                if let listed = try await pick(sessionKeyService.sessionKeys()) {
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
}

// MARK: - Batches

private extension CommonPolymarketSessionKeyManager {
    var authorizations: PolymarketSessionKeyAuthorizations {
        PolymarketSessionKeyAuthorizations(userWalletId: userWalletId, keyStore: keyStore, serverClock: serverClock)
    }

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
            deadline: makeDeadline(offset: PolymarketSessionKeyAuthorizationBatch.deadlineOffset),
            calls: [call]
        )
    }

    func makeDeadline(offset: Int) -> String {
        String(Int(serverClock.now.timeIntervalSince1970) + offset)
    }

    enum Constants {
        static let pollingInterval: TimeInterval = 3
        static let readinessAttempts = 10
        static let resubmitAttempts = 3
        static let busyRetryAttempts = 3
        static let busyRetryDelay: TimeInterval = 1.5
        static let deviceNameLimit = 64
    }
}

// MARK: - Authorization batch

struct PolymarketSessionKeyAuthorizationBatch {
    static let deadlineOffset = 600
    static let followUpDeadlineOffset = 1200

    static func nonce(following nonce: String) throws -> String {
        guard let value = Int(nonce) else {
            throw PolymarketSessionKeyManagerError.unparseableNonce(nonce)
        }

        return String(value + 1)
    }

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

// MARK: - Authorizations

struct PolymarketSessionKeyAuthorizations {
    let userWalletId: UserWalletId
    let keyStore: PolymarketSessionKeyStore
    let serverClock: PolymarketServerClock

    func heldOrNewKeyAddress() throws -> String {
        try keyStore.heldAddress(for: userWalletId) ?? keyStore.generateKey(for: userWalletId)
    }

    func makeFollowUp(depositWalletAddress: String, nonce: String) throws -> PolymarketSessionKeyAuthorizationBatch {
        try PolymarketSessionKeyAuthorizationBatch(
            sessionKeyAddress: heldOrNewKeyAddress(),
            depositWalletAddress: depositWalletAddress,
            nonce: nonce,
            now: serverClock.now,
            deadlineOffset: PolymarketSessionKeyAuthorizationBatch.followUpDeadlineOffset
        )
    }
}

// MARK: - Settling misses

extension PolymarketSessionKey {
    static let settlingMissTolerance = 3
    static let settlingGrace: TimeInterval = 60
}

// MARK: - Backend hold

extension PolymarketSessionKey {
    static let backendHoldGrace: TimeInterval = 10 * 60
    static let backendHoldLimit: TimeInterval = 30 * 60
    static let backendHoldWindow = min(
        TimeInterval(PolymarketSessionKeyAuthorizationBatch.followUpDeadlineOffset) + backendHoldGrace,
        backendHoldLimit
    )
}

// MARK: - Cancellation

extension PolymarketSessionKeyError {
    static func isCancellation(_ error: Error) -> Bool {
        switch error {
        case is CancellationError, PolymarketSessionKeyError.cancelled:
            true
        default:
            false
        }
    }
}

// MARK: - Refusals

extension PolymarketSessionKeyError {
    var isBusyRefusal: Bool {
        guard case .refused(_, let reason, let detail) = self else {
            return false
        }

        switch reason {
        case .busy, .deviceHasSessionKey:
            return true
        case .relayerRejected:
            return detail?.localizedCaseInsensitiveContains(Self.relayerInFlightMarker) == true
        case .malformedRequest, .invalidWalletId, .invalidDeadline, .invalidValidUntil, .invalidCall, .invalidSignature,
             .walletNotOwned, .walletNotReady, .ownedByAnotherWallet, .invalidReplacement, .limitReached, .notToggleable,
             .notFound, .nonceAlreadyUsed, .unknown:
            return false
        }
    }

    private static let relayerInFlightMarker = "in-flight"
}

// MARK: - Grant records

extension Sequence where Element == PolymarketSessionKey {
    func record(of grant: PolymarketSessionKeyGrant) -> PolymarketSessionKey? {
        filter { $0.isRecord(of: grant) }.decisiveRecord(of: grant.sessionKeyAddress)
    }
}

private extension PolymarketSessionKey {
    func isRecord(of grant: PolymarketSessionKeyGrant) -> Bool {
        guard address.caseInsensitiveCompare(grant.sessionKeyAddress) == .orderedSame, let validUntil else {
            return false
        }

        return Int(validUntil.timeIntervalSince1970) == Int(grant.validUntil.timeIntervalSince1970)
    }
}

// MARK: - Accepted requests

private extension PolymarketSessionKey {
    func showsAuthorization(of grant: PolymarketSessionKeyGrant) -> Bool {
        (status == .pending || status == .active) && isRecord(of: grant)
    }

    var showsRevocation: Bool {
        status == .revoking || status == .revoked
    }
}
