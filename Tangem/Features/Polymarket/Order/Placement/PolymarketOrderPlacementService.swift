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

        return try await placer.place(
            PolymarketOrderPlacer.Options(
                quote: quote,
                assetId: outcome.assetId,
                isNegRisk: market.isNegRisk,
                ownerAddress: ownerAddress,
                depositWalletAddress: depositWalletAddress,
                credentials: credentials
            )
        )
    }
}
