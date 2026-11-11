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
    private let interruptedAuthorizations: PolymarketInterruptedAuthorizationStore
    private let now: @Sendable () -> Date

    private nonisolated(unsafe) let refusals = PassthroughSubject<Void, Never>()
    private let refusalsByAddress = OSAllocatedUnfairLock<[String: PolymarketOrderSigningRefusal]>(initialState: [:])
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
        interruptedAuthorizations: PolymarketInterruptedAuthorizationStore,
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
        self.interruptedAuthorizations = interruptedAuthorizations
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

        guard
            let sessionKeyAddress = heldAddress,
            !isRefused(sessionKeyAddress: sessionKeyAddress),
            !isKeptPaused(sessionKeyAddress: sessionKeyAddress)
        else {
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
        } catch let error as PolymarketAPIError where error.isUnauthorized {
            PolymarketLogger.error("The exchange refused credentials to the session key, signing with the owner key", error: error)

            if generation == routedGeneration {
                reportRefused(sessionKeyAddress: sessionKeyAddress)
            }

            return .ownerKey
        } catch where Self.leavesTheKeyNotReady(error) {
            PolymarketLogger.error("Failed to obtain the session key credentials, signing with the owner key", error: error)

            if generation == routedGeneration {
                readinessChecks[sessionKeyAddress] = .notReady(checkedAt: now())
            }

            return .ownerKey
        } catch {
            PolymarketLogger.error("Failed to obtain the session key credentials, the order is not placed", error: error)
            return .unverified
        }
    }

    nonisolated var refusalsPublisher: AnyPublisher<Void, Never> {
        refusals.eraseToAnyPublisher()
    }

    func reportRefused(sessionKeyAddress: String) {
        generation += 1

        let refusedAt = now()
        let routedOn = readinessChecks[sessionKeyAddress]?.confirmation

        refusalsByAddress.withLock { stored in
            stored[sessionKeyAddress] = PolymarketOrderSigningRefusal(
                refusedAt: refusedAt,
                routedOn: routedOn ?? stored[sessionKeyAddress]?.routedOn
            )
        }

        readinessChecks[sessionKeyAddress] = nil
        sessionCredentialsProvider.reset()
        refusals.send()
    }

    func invalidate(sessionKeyAddress: String) {
        generation += 1
        readinessChecks.removeAll()
        refusalsByAddress.withLock { _ = $0.removeValue(forKey: sessionKeyAddress) }
        sessionCredentialsProvider.reset()
    }

    func forgetReadiness() {
        generation += 1
        readinessChecks.removeAll()
    }

    nonisolated func refusal(of sessionKeyAddress: String) -> PolymarketOrderSigningRefusal? {
        refusalsByAddress.withLock { $0[sessionKeyAddress] }
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
        case until(Date, PolymarketSessionKeyConfirmation)
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
        case .until(let usableUntil, let confirmation):
            readinessChecks[sessionKeyAddress] = .ready(until: usableUntil, checkedAt: checkedAt, confirmation: confirmation)
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

        guard let signer, let signerValidUntil = signer.validUntil else {
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

        return .until(
            min(signerValidUntil, recordValidUntil).addingTimeInterval(-PolymarketSessionKey.signingExpiryMargin),
            PolymarketSessionKeyConfirmation(record: record, signer: signer)
        )
    }

    func backendRecord(sessionKeyAddress: String) async throws -> PolymarketSessionKey? {
        try await sessionKeyService.sessionKeys().decisiveRecord(of: sessionKeyAddress)
    }

    func isKeptPaused(sessionKeyAddress: String) -> Bool {
        do {
            return try interruptedAuthorizations.load(for: userWalletId)?.keepsPaused(sessionKeyAddress: sessionKeyAddress) ?? false
        } catch {
            PolymarketLogger.error("Failed to read whether the session key is kept paused, signing with the owner key", error: error)
            return true
        }
    }

    static func leavesTheKeyNotReady(_ error: Error) -> Bool {
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
        let confirmation: PolymarketSessionKeyConfirmation?

        static func ready(until usableUntil: Date, checkedAt: Date, confirmation: PolymarketSessionKeyConfirmation) -> ReadinessCheck {
            ReadinessCheck(
                isReady: true,
                expiresAt: min(checkedAt.addingTimeInterval(Constants.confirmationLifetime), usableUntil),
                confirmation: confirmation
            )
        }

        static func notReady(checkedAt: Date) -> ReadinessCheck {
            ReadinessCheck(isReady: false, expiresAt: checkedAt.addingTimeInterval(Constants.notReadyLifetime), confirmation: nil)
        }
    }

    enum Constants {
        static let confirmationLifetime: TimeInterval = 5 * 60
        static let notReadyLifetime: TimeInterval = 60
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
