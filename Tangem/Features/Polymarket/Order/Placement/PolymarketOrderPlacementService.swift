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
        outcome: PolymarketOutcome
    ) async throws -> PolymarketOrderPlacement
}

enum PolymarketOrderPlacementSetupError: Error {
    case ownerAddressUnavailable
    case credentialsUnavailable
}

struct CommonPolymarketOrderPlacementService {
    private let userWalletId: UserWalletId
    private let ownerAddressProvider: PolymarketOwnerAddressProviding
    private let credentialsRepository: PolymarketCredentialsRepository
    private let placer: PolymarketOrderPlacing

    init(
        userWalletId: UserWalletId,
        ownerAddressProvider: PolymarketOwnerAddressProviding,
        credentialsRepository: PolymarketCredentialsRepository,
        placer: PolymarketOrderPlacing
    ) {
        self.userWalletId = userWalletId
        self.ownerAddressProvider = ownerAddressProvider
        self.credentialsRepository = credentialsRepository
        self.placer = placer
    }
}

// MARK: - PolymarketOrderPlacementService protocol conformance

extension CommonPolymarketOrderPlacementService: PolymarketOrderPlacementService {
    func place(
        quote: PolymarketOrderQuote,
        market: PolymarketMarket,
        outcome: PolymarketOutcome
    ) async throws -> PolymarketOrderPlacement {
        guard let ownerAddress = ownerAddressProvider.getOwnerAddress() else {
            throw PolymarketOrderPlacementSetupError.ownerAddressUnavailable
        }

        guard let credentials = credentialsRepository.load(userWalletId: userWalletId) else {
            throw PolymarketOrderPlacementSetupError.credentialsUnavailable
        }

        let depositWalletAddress = try PolymarketDepositWalletDeriver.derive(ownerAddress: ownerAddress)

        let placement = try await placer.place(
            PolymarketOrderPlacer.Options(
                quote: quote,
                assetId: outcome.assetId,
                isNegRisk: market.isNegRisk,
                ownerAddress: ownerAddress,
                depositWalletAddress: depositWalletAddress,
                credentials: credentials
            )
        )

        guard placement.status == .delayed, let orderId = placement.orderId else {
            return placement
        }

        return try await settled(
            orderId: orderId,
            side: quote.side,
            credentials: credentials,
            ownerAddress: ownerAddress
        )
    }
}

// MARK: - Orders a delayed market has not filled yet

private extension CommonPolymarketOrderPlacementService {
    /// A market that delays its trading accepts the order and fills nothing, so the fill has to be read
    /// back. Running out of patience is not a refusal — the order may still be live, and the screen that
    /// says so is the one an ambiguous outcome already leads to.
    func settled(
        orderId: String,
        side: PolymarketOrderSide,
        credentials: PolymarketL2Credentials,
        ownerAddress: String
    ) async throws -> PolymarketOrderPlacement {
        let deadline = Date().addingTimeInterval(Constants.settlementTimeout)

        while Date() < deadline {
            try await Task.sleep(nanoseconds: Constants.pollIntervalNanoseconds)
            try Task.checkCancellation()

            let record: PolymarketOrderRecord

            do {
                record = try await placer.order(id: orderId, credentials: credentials, ownerAddress: ownerAddress)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                PolymarketLogger.error("Failed to read back a delayed order", error: error)
                throw PolymarketOrderPlacementError.ambiguous(underlying: error)
            }

            switch record.status {
            case .matched:
                return .settled(record, orderId: orderId, side: side)
            case .live:
                continue
            case .canceled, .canceledMarketResolved, .invalid, .unknown:
                throw PolymarketOrderPlacementError.rejected(message: nil)
            }
        }

        throw PolymarketOrderPlacementError.ambiguous(underlying: SettlementError.neverSettled)
    }

    enum SettlementError: Error {
        case neverSettled
    }

    enum Constants {
        static let pollIntervalNanoseconds: UInt64 = 10 * NSEC_PER_SEC
        static let settlementTimeout: TimeInterval = 30
    }
}
