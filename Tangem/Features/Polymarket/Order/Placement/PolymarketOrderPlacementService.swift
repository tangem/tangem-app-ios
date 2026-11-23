//
//  PolymarketOrderPlacementService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPolymarket

protocol PolymarketOrderPlacementService {
    func place(
        quote: PolymarketOrderQuote,
        market: PolymarketMarket,
        outcome: PolymarketOutcome,
        signing: PolymarketOrderSigningRoute
    ) async throws -> PolymarketOrderPlacement
}

enum PolymarketOrderSigningMethod: Equatable {
    case ownerKey
    case sessionKey
}

enum PolymarketOrderPlacementSetupError: Error {
    case ownerAddressUnavailable
    case credentialsUnavailable
    case sessionKeyUnavailable
}

struct CommonPolymarketOrderPlacementService {
    private let userWalletId: UserWalletId
    private let ownerAddressProvider: PolymarketOwnerAddressProviding
    private let credentialsRepository: PolymarketCredentialsRepository
    private let placer: PolymarketOrderPlacing
    private let sessionKeyPlacement: SessionKeyPlacement
    private let delayProvider: PollDelayProvider

    init(
        userWalletId: UserWalletId,
        ownerAddressProvider: PolymarketOwnerAddressProviding,
        credentialsRepository: PolymarketCredentialsRepository,
        placer: PolymarketOrderPlacing,
        sessionKeyPlacement: SessionKeyPlacement,
        delayProvider: PollDelayProvider = TaskSleepPollDelayProvider()
    ) {
        self.userWalletId = userWalletId
        self.ownerAddressProvider = ownerAddressProvider
        self.credentialsRepository = credentialsRepository
        self.placer = placer
        self.sessionKeyPlacement = sessionKeyPlacement
        self.delayProvider = delayProvider
    }
}

// MARK: - Session key placement

extension CommonPolymarketOrderPlacementService {
    struct SessionKeyPlacement {
        let placer: PolymarketOrderPlacing
        let router: PolymarketOrderSigningRouting
    }
}

// MARK: - PolymarketOrderPlacementService protocol conformance

extension CommonPolymarketOrderPlacementService: PolymarketOrderPlacementService {
    func place(
        quote: PolymarketOrderQuote,
        market: PolymarketMarket,
        outcome: PolymarketOutcome,
        signing: PolymarketOrderSigningRoute
    ) async throws -> PolymarketOrderPlacement {
        guard let ownerAddress = ownerAddressProvider.getOwnerAddress() else {
            throw PolymarketOrderPlacementSetupError.ownerAddressUnavailable
        }

        let depositWalletAddress = try PolymarketDepositWalletDeriver.derive(ownerAddress: ownerAddress)

        switch signing {
        case .sessionKey(let session):
            return try await placeWithSessionKey(
                session,
                quote: quote,
                market: market,
                outcome: outcome,
                depositWalletAddress: depositWalletAddress
            )
        case .ownerKey:
            guard let credentials = credentialsRepository.load(userWalletId: userWalletId) else {
                throw PolymarketOrderPlacementSetupError.credentialsUnavailable
            }

            return try await place(
                with: placer,
                quote: quote,
                market: market,
                outcome: outcome,
                signer: Signer(address: ownerAddress, credentials: credentials),
                depositWalletAddress: depositWalletAddress
            )
        }
    }
}

// MARK: - Placement

private extension CommonPolymarketOrderPlacementService {
    func placeWithSessionKey(
        _ session: PolymarketSessionCredentials,
        quote: PolymarketOrderQuote,
        market: PolymarketMarket,
        outcome: PolymarketOutcome,
        depositWalletAddress: String
    ) async throws -> PolymarketOrderPlacement {
        do {
            return try await place(
                with: sessionKeyPlacement.placer,
                quote: quote,
                market: market,
                outcome: outcome,
                signer: Signer(address: session.sessionKeyAddress, credentials: session.credentials),
                depositWalletAddress: depositWalletAddress
            )
        } catch let error as PolymarketOrderPlacementError where error.refusesTheSessionKey {
            PolymarketLogger.error("The session key failed or was refused, the order waits for the owner's signature", error: error)
            await sessionKeyPlacement.router.reportRefused(sessionKeyAddress: session.sessionKeyAddress)
            throw PolymarketOrderPlacementSetupError.sessionKeyUnavailable
        }
    }

    struct Signer {
        let address: String
        let credentials: PolymarketL2Credentials
    }

    func place(
        with placer: PolymarketOrderPlacing,
        quote: PolymarketOrderQuote,
        market: PolymarketMarket,
        outcome: PolymarketOutcome,
        signer: Signer,
        depositWalletAddress: String
    ) async throws -> PolymarketOrderPlacement {
        let placement = try await placer.place(
            PolymarketOrderPlacer.Options(
                quote: quote,
                assetId: outcome.assetId,
                isNegRisk: market.isNegRisk,
                signingKeyAddress: signer.address,
                depositWalletAddress: depositWalletAddress,
                credentials: signer.credentials
            )
        )

        guard placement.status == .delayed, let orderId = placement.orderId else {
            return placement
        }

        return try await settled(
            orderId: orderId,
            side: quote.side,
            placer: placer,
            credentials: signer.credentials,
            signingKeyAddress: signer.address
        )
    }
}

// MARK: - Orders a delayed market has not filled yet

private extension CommonPolymarketOrderPlacementService {
    func settled(
        orderId: String,
        side: PolymarketOrderSide,
        placer: PolymarketOrderPlacing,
        credentials: PolymarketL2Credentials,
        signingKeyAddress: String
    ) async throws -> PolymarketOrderPlacement {
        var budget = Constants.settlementBudget

        while budget > .zero {
            try await delayProvider.wait(for: Constants.pollIntervalSeconds)
            try Task.checkCancellation()

            let readStart = ContinuousClock.now
            let record: PolymarketOrderRecord

            do {
                record = try await placer.order(id: orderId, credentials: credentials, signingKeyAddress: signingKeyAddress)
                budget -= Self.cost(ofReadStartedAt: readStart)
            } catch is CancellationError {
                throw CancellationError()
            } catch let error as PolymarketAPIError where error.isRetryable {
                PolymarketLogger.error("Failed to read back a delayed order, reading it again", error: error)
                budget -= Self.cost(ofReadStartedAt: readStart)
                continue
            } catch let error as PolymarketAPIError where error.isClientRefusal {
                PolymarketLogger.error("The exchange refused to read back a delayed order", error: error)
                throw PolymarketOrderPlacementError.rejected(message: nil)
            } catch {
                PolymarketLogger.error("Failed to read back a delayed order", error: error)
                throw PolymarketOrderPlacementError.ambiguous(underlying: error)
            }

            switch record.status {
            case .matched:
                return .settled(record, orderId: orderId, side: side)
            case .live, .unknown:
                continue
            case .canceled, .canceledMarketResolved, .invalid:
                throw PolymarketOrderPlacementError.rejected(message: nil)
            }
        }

        throw PolymarketOrderPlacementError.ambiguous(underlying: SettlementError.neverSettled)
    }

    static func cost(ofReadStartedAt start: ContinuousClock.Instant) -> Duration {
        Constants.pollInterval + min(start.duration(to: .now), Constants.maxReadCost)
    }

    enum SettlementError: Error {
        case neverSettled
    }

    enum Constants {
        static let pollIntervalSeconds: TimeInterval = 10
        static let pollInterval: Duration = .seconds(pollIntervalSeconds)
        static let settlementBudget: Duration = .seconds(30)
        static let maxReadCost: Duration = .seconds(10)
    }
}

// MARK: - Session key refusals

private extension PolymarketOrderPlacementError {
    var refusesTheSessionKey: Bool {
        switch self {
        case .unauthorized:
            return true
        // [REDACTED_TODO_COMMENT]
        case .rejected(let message):
            guard let message else { return false }

            return RefusalMarkers.all.contains { message.localizedCaseInsensitiveContains($0) }
        case .notSent(let underlying):
            return underlying.isSessionKeyFailure
        case .noLiquidity, .ambiguous:
            return false
        }
    }

    enum RefusalMarkers {
        static let all = ["signature", "signer", "unauthorized", "api key"]
    }
}

private extension Error {
    var isSessionKeyFailure: Bool {
        self is CommonPolymarketSessionKeyStore.KeyError
            || self is PolymarketSessionKeySignatureError
            || self is PolymarketL2AuthError
    }
}
