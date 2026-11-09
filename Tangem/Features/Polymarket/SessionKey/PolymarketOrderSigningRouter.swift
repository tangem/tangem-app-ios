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

protocol PolymarketOrderSigningRouting {
    func route() async -> PolymarketOrderSigningRoute

    var refusalsPublisher: AnyPublisher<Void, Never> { get }

    func reportRefused(sessionKeyAddress: String) async

    func invalidate(sessionKeyAddress: String) async

    func forgetReadiness() async

    func isRefused(sessionKeyAddress: String) -> Bool
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
    private let now: () -> Date

    private nonisolated(unsafe) let refusals = PassthroughSubject<Void, Never>()
    private let refusedAddresses = OSAllocatedUnfairLock<Set<String>>(initialState: [])
    private var readinessChecks: [String: ReadinessCheck] = [:]
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
        now: @escaping () -> Date = Date.init
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

        guard
            isEligible,
            let sessionKeyAddress = try? keyStore.heldAddress(for: userWalletId),
            !isRefused(sessionKeyAddress: sessionKeyAddress),
            await isReady(sessionKeyAddress: sessionKeyAddress, generation: routedGeneration)
        else {
            return .ownerKey
        }

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
        } catch {
            PolymarketLogger.error("Failed to obtain the session key credentials, signing with the owner key", error: error)

            if generation == routedGeneration {
                readinessChecks[sessionKeyAddress] = .notReady(checkedAt: now())
            }

            return .ownerKey
        }
    }

    nonisolated var refusalsPublisher: AnyPublisher<Void, Never> {
        refusals.eraseToAnyPublisher()
    }

    func reportRefused(sessionKeyAddress: String) {
        generation += 1
        refusedAddresses.withLock { _ = $0.insert(sessionKeyAddress) }
        readinessChecks[sessionKeyAddress] = nil
        refusals.send()
    }

    func invalidate(sessionKeyAddress: String) {
        generation += 1
        readinessChecks.removeAll()
        refusedAddresses.withLock { _ = $0.remove(sessionKeyAddress) }
        sessionCredentialsProvider.reset()
    }

    func forgetReadiness() {
        generation += 1
        readinessChecks.removeAll()
    }

    nonisolated func isRefused(sessionKeyAddress: String) -> Bool {
        refusedAddresses.withLock { $0.contains(sessionKeyAddress) }
    }
}

// MARK: - Readiness

private extension CommonPolymarketOrderSigningRouter {
    func isReady(sessionKeyAddress: String, generation checkedGeneration: Int) async -> Bool {
        if let check = readinessChecks[sessionKeyAddress], now() < check.expiresAt {
            return check.isReady
        }

        let usableUntil = await usableUntil(sessionKeyAddress: sessionKeyAddress)

        guard generation == checkedGeneration else {
            return false
        }

        let checkedAt = now()
        readinessChecks[sessionKeyAddress] = usableUntil.map { .ready(until: $0, checkedAt: checkedAt) } ?? .notReady(checkedAt: checkedAt)

        return usableUntil != nil
    }

    func usableUntil(sessionKeyAddress: String) async -> Date? {
        guard
            let ownerAddress = ownerAddressProvider.getOwnerAddress(),
            let ownerCredentials = credentialsRepository.load(userWalletId: userWalletId)
        else {
            return nil
        }

        let signers: [PolymarketSessionSigner]

        do {
            signers = try await clobService.sessionSigners(credentials: ownerCredentials, ownerAddress: ownerAddress)
        } catch {
            PolymarketLogger.error("Failed to read the session signers, signing with the owner key", error: error)
            return nil
        }

        let signer = signers.first { signer in
            signer.address == sessionKeyAddress && signer.isUsable(at: now())
        }

        guard let signerValidUntil = signer?.validUntil else {
            return nil
        }

        guard
            let record = await backendRecord(sessionKeyAddress: sessionKeyAddress),
            record.isUsable(at: now()),
            let recordValidUntil = record.validUntil
        else {
            return nil
        }

        return min(signerValidUntil, recordValidUntil).addingTimeInterval(-PolymarketSessionKey.signingExpiryMargin)
    }

    func backendRecord(sessionKeyAddress: String) async -> PolymarketSessionKey? {
        do {
            return try await sessionKeyService.sessionKeys().first { $0.address == sessionKeyAddress }
        } catch {
            PolymarketLogger.warning("Failed to read the session keys of the wallet, signing with the owner key")
            return nil
        }
    }

    struct ReadinessCheck {
        let isReady: Bool
        let expiresAt: Date

        static func ready(until usableUntil: Date, checkedAt: Date) -> ReadinessCheck {
            ReadinessCheck(isReady: true, expiresAt: min(checkedAt.addingTimeInterval(Constants.confirmationLifetime), usableUntil))
        }

        static func notReady(checkedAt: Date) -> ReadinessCheck {
            ReadinessCheck(isReady: false, expiresAt: checkedAt.addingTimeInterval(Constants.refusalLifetime))
        }
    }

    enum Constants {
        static let confirmationLifetime: TimeInterval = 5 * 60
        static let refusalLifetime: TimeInterval = 60
    }
}

// MARK: - Session signer usability

extension PolymarketSessionSigner {
    func isUsable(at date: Date) -> Bool {
        guard hasTradingScope, let validUntil else {
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
