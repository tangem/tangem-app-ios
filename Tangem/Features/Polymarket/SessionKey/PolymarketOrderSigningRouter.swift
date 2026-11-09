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
    case unverified
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

        guard isEligible else {
            return .ownerKey
        }

        let heldAddress: String?

        do {
            heldAddress = try keyStore.heldAddress(for: userWalletId)
        } catch {
            PolymarketLogger.error("Failed to read the session key address, the order is not placed", error: error)
            return .unverified
        }

        guard let sessionKeyAddress = heldAddress, !isRefused(sessionKeyAddress: sessionKeyAddress) else {
            return .ownerKey
        }

        switch await readiness(sessionKeyAddress: sessionKeyAddress, generation: routedGeneration) {
        case .ready:
            break
        case .notReady:
            return .ownerKey
        case .unverified:
            return .unverified
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
            guard Self.isRefusal(error) else {
                PolymarketLogger.error("Failed to obtain the session key credentials, the order is not placed", error: error)
                return .unverified
            }

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
    enum Readiness {
        case ready
        case notReady
        case unverified
    }

    enum UsableWindow {
        case until(Date)
        case unusable
        case unverified
    }

    func readiness(sessionKeyAddress: String, generation checkedGeneration: Int) async -> Readiness {
        if let check = readinessChecks[sessionKeyAddress], now() < check.expiresAt {
            return check.isReady ? .ready : .notReady
        }

        let window = await usableWindow(sessionKeyAddress: sessionKeyAddress)

        guard generation == checkedGeneration else {
            return .notReady
        }

        let checkedAt = now()

        switch window {
        case .until(let usableUntil):
            readinessChecks[sessionKeyAddress] = .ready(until: usableUntil, checkedAt: checkedAt)
            return .ready
        case .unusable:
            readinessChecks[sessionKeyAddress] = .notReady(checkedAt: checkedAt)
            return .notReady
        case .unverified:
            return .unverified
        }
    }

    func usableWindow(sessionKeyAddress: String) async -> UsableWindow {
        let storedCredentials: PolymarketL2Credentials?

        do {
            storedCredentials = try credentialsRepository.readCredentials(userWalletId: userWalletId)
        } catch {
            PolymarketLogger.error("Failed to read the owner credentials, the order is not placed", error: error)
            return .unverified
        }

        guard let ownerAddress = ownerAddressProvider.getOwnerAddress(), let ownerCredentials = storedCredentials else {
            return .unusable
        }

        let signers: [PolymarketSessionSigner]

        do {
            signers = try await clobService.sessionSigners(credentials: ownerCredentials, ownerAddress: ownerAddress)
        } catch {
            PolymarketLogger.error("Failed to read the session signers", error: error)
            return Self.isRetryable(error) ? .unverified : .unusable
        }

        let signer = signers.first { signer in
            signer.address == sessionKeyAddress && signer.isUsable(at: now())
        }

        guard let signerValidUntil = signer?.validUntil else {
            return .unusable
        }

        let record: PolymarketSessionKey?

        do {
            record = try await backendRecord(sessionKeyAddress: sessionKeyAddress)
        } catch {
            PolymarketLogger.warning("Failed to read the session keys of the wallet")
            return Self.isRetryable(error) ? .unverified : .unusable
        }

        guard let record, record.isUsable(at: now()), let recordValidUntil = record.validUntil else {
            return .unusable
        }

        return .until(min(signerValidUntil, recordValidUntil).addingTimeInterval(-PolymarketSessionKey.signingExpiryMargin))
    }

    func backendRecord(sessionKeyAddress: String) async throws -> PolymarketSessionKey? {
        try await sessionKeyService.sessionKeys().first { $0.address == sessionKeyAddress }
    }

    static func isRefusal(_ error: Error) -> Bool {
        switch error {
        case is CommonPolymarketSessionKeyStore.KeyError:
            true
        case is PolymarketAPIError, is PolymarketSessionKeyError:
            !isRetryable(error)
        default:
            false
        }
    }

    static func isRetryable(_ error: Error) -> Bool {
        switch error {
        case let error as PolymarketAPIError:
            error.isRetryable
        case PolymarketSessionKeyError.other(let error):
            error.isRetryable
        case PolymarketSessionKeyError.cancelled, is CancellationError:
            true
        default:
            false
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
