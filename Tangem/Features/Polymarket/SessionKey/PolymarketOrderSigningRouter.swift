//
//  PolymarketOrderSigningRouter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemPolymarket

enum PolymarketOrderSigningRoute: Hashable {
    case ownerKey
    case sessionKey(PolymarketSessionCredentials)
}

struct PolymarketSessionKeyConfirmation: Equatable, Sendable {
    let record: PolymarketSessionKey
    let signer: PolymarketSessionSigner
}

struct PolymarketOrderSigningRefusal: Equatable, Sendable {
    let refusedAt: Date
    let routedOn: PolymarketSessionKeyConfirmation?
}

protocol PolymarketOrderSigningRouting {
    func route() async -> PolymarketOrderSigningRoute

    var refusalsPublisher: AnyPublisher<Void, Never> { get }

    func reportRefused(sessionKeyAddress: String) async

    func invalidate(sessionKeyAddress: String) async

    func forgetReadiness() async

    func refusal(of sessionKeyAddress: String) -> PolymarketOrderSigningRefusal?
}

extension PolymarketOrderSigningRouting {
    func isRefused(sessionKeyAddress: String) -> Bool {
        refusal(of: sessionKeyAddress) != nil
    }
}

actor CommonPolymarketOrderSigningRouter {
    private let userWalletId: UserWalletId
    private let isEligible: Bool
    private let keyStore: PolymarketSessionKeyStore
    private let sessionCredentialsProvider: PolymarketSessionCredentialsProviding
    private let clobService: PolymarketCLOBService
    private let sessionKeyService: PolymarketSessionKeyService
    private let credentialsRepository: PolymarketCredentialsRepository
    private let ownerAddressProvider: PolymarketOwnerAddressProviding
    private let now: @Sendable () -> Date

    private nonisolated(unsafe) let refusals = PassthroughSubject<Void, Never>()
    private let refusalsByAddress = OSAllocatedUnfairLock<[String: PolymarketOrderSigningRefusal]>(initialState: [:])
    private var confirmations: [String: PolymarketSessionKeyConfirmation] = [:]
    private var generation = 0

    init(
        userWalletId: UserWalletId,
        isEligible: Bool,
        keyStore: PolymarketSessionKeyStore,
        sessionCredentialsProvider: PolymarketSessionCredentialsProviding,
        clobService: PolymarketCLOBService,
        sessionKeyService: PolymarketSessionKeyService,
        credentialsRepository: PolymarketCredentialsRepository,
        ownerAddressProvider: PolymarketOwnerAddressProviding,
        now: @escaping @Sendable () -> Date = { InjectedValues[\.polymarketServerClock].now }
    ) {
        self.userWalletId = userWalletId
        self.isEligible = isEligible
        self.keyStore = keyStore
        self.sessionCredentialsProvider = sessionCredentialsProvider
        self.clobService = clobService
        self.sessionKeyService = sessionKeyService
        self.credentialsRepository = credentialsRepository
        self.ownerAddressProvider = ownerAddressProvider
        self.now = now
    }
}

// MARK: - PolymarketOrderSigningRouting protocol conformance

extension CommonPolymarketOrderSigningRouter: PolymarketOrderSigningRouting {
    func route() async -> PolymarketOrderSigningRoute {
        let routedGeneration = generation

        guard isEligible else {
            return .ownerKey
        }

        let heldAddress: String?

        do {
            heldAddress = try keyStore.heldAddress(for: userWalletId)
        } catch {
            PolymarketLogger.error("Failed to read the session key address, signing with the owner key", error: error)
            return .ownerKey
        }

        guard let sessionKeyAddress = heldAddress, !isRefused(sessionKeyAddress: sessionKeyAddress) else {
            return .ownerKey
        }

        let confirmation = await confirmation(sessionKeyAddress: sessionKeyAddress)

        guard let confirmation, generation == routedGeneration else {
            return .ownerKey
        }

        confirmations[sessionKeyAddress] = confirmation

        do {
            let session = try await sessionCredentialsProvider.credentials()

            guard
                session.sessionKeyAddress == sessionKeyAddress,
                generation == routedGeneration,
                !isRefused(sessionKeyAddress: sessionKeyAddress)
            else {
                return .ownerKey
            }

            return .sessionKey(session)
        } catch let error as PolymarketAPIError where error.isUnauthorized {
            PolymarketLogger.error("The exchange refused credentials to the session key, signing with the owner key", error: error)

            if generation == routedGeneration {
                reportRefused(sessionKeyAddress: sessionKeyAddress)
            }

            return .ownerKey
        } catch {
            PolymarketLogger.error("Failed to obtain the session key credentials, signing with the owner key", error: error)
            return .ownerKey
        }
    }

    nonisolated var refusalsPublisher: AnyPublisher<Void, Never> {
        refusals.eraseToAnyPublisher()
    }

    func reportRefused(sessionKeyAddress: String) {
        generation += 1

        let refusedAt = now()
        let routedOn = confirmations[sessionKeyAddress]

        refusalsByAddress.withLock { stored in
            stored[sessionKeyAddress] = PolymarketOrderSigningRefusal(
                refusedAt: refusedAt,
                routedOn: routedOn ?? stored[sessionKeyAddress]?.routedOn
            )
        }

        confirmations[sessionKeyAddress] = nil
        sessionCredentialsProvider.reset()
        refusals.send()
    }

    func invalidate(sessionKeyAddress: String) {
        generation += 1
        confirmations.removeAll()
        refusalsByAddress.withLock { _ = $0.removeValue(forKey: sessionKeyAddress) }
        sessionCredentialsProvider.reset()
    }

    func forgetReadiness() {
        generation += 1
        confirmations.removeAll()
    }

    nonisolated func refusal(of sessionKeyAddress: String) -> PolymarketOrderSigningRefusal? {
        refusalsByAddress.withLock { $0[sessionKeyAddress] }
    }
}

// MARK: - Readiness

private extension CommonPolymarketOrderSigningRouter {
    func confirmation(sessionKeyAddress: String) async -> PolymarketSessionKeyConfirmation? {
        let storedCredentials: PolymarketL2Credentials?

        do {
            storedCredentials = try credentialsRepository.readCredentials(userWalletId: userWalletId)
        } catch {
            PolymarketLogger.error("Failed to read the owner credentials, signing with the owner key", error: error)
            return nil
        }

        guard let ownerAddress = ownerAddressProvider.getOwnerAddress(), let ownerCredentials = storedCredentials else {
            return nil
        }

        let signers: [PolymarketSessionSigner]

        do {
            signers = try await clobService.sessionSigners(credentials: ownerCredentials, ownerAddress: ownerAddress)
        } catch {
            PolymarketLogger.error("Failed to read the session signers", error: error)
            return nil
        }

        let signer = signers.first { signer in
            signer.address == sessionKeyAddress && signer.isUsable(at: now())
        }

        guard let signer else {
            return nil
        }

        let record: PolymarketSessionKey?

        do {
            record = try await backendRecord(sessionKeyAddress: sessionKeyAddress)
        } catch {
            PolymarketLogger.warning("Failed to read the session keys of the wallet")
            return nil
        }

        guard let record, record.isUsable(at: now()), signer.hasTerms(of: record) else {
            return nil
        }

        return PolymarketSessionKeyConfirmation(record: record, signer: signer)
    }

    func backendRecord(sessionKeyAddress: String) async throws -> PolymarketSessionKey? {
        try await sessionKeyService.sessionKeys().decisiveRecord(of: sessionKeyAddress)
    }
}

// MARK: - Session signer usability

extension PolymarketSessionSigner {
    func isUsable(at date: Date) -> Bool {
        guard hasTradingTerms, let validUntil else {
            return false
        }

        return validUntil.timeIntervalSince(date) > PolymarketSessionKey.signingExpiryMargin
    }
}

// MARK: - Session key usability

extension PolymarketSessionKey {
    static let signingExpiryMargin: TimeInterval = 10 * 60

    func isUsable(at date: Date) -> Bool {
        guard status == .active, isEnabled, let validUntil else {
            return false
        }

        return validUntil.timeIntervalSince(date) > Self.signingExpiryMargin
    }
}
