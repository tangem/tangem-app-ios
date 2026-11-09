//
//  PolymarketActivityService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

protocol PolymarketActivityService {
    func activity(filter: PolymarketActivityFilter, limit: Int, cursor: String?) async throws -> PolymarketActivityPage

    @discardableResult
    func reconcileDeposits() async -> PolymarketDepositsScan?
}

struct CommonPolymarketActivityService {
    private let ownerAddressProvider: PolymarketOwnerAddressProviding
    private let apiProvider: PolymarketAPIProvider

    init(ownerAddressProvider: PolymarketOwnerAddressProviding, apiProvider: PolymarketAPIProvider) {
        self.ownerAddressProvider = ownerAddressProvider
        self.apiProvider = apiProvider
    }
}

// MARK: - PolymarketActivityService protocol conformance

extension CommonPolymarketActivityService: PolymarketActivityService {
    func activity(filter: PolymarketActivityFilter, limit: Int, cursor: String?) async throws -> PolymarketActivityPage {
        try await apiProvider.activity(
            request: PolymarketActivityRequest(
                depositWalletAddress: ownerAddressProvider.depositWalletAddress(),
                type: filter.type,
                redeemResult: filter.redeemResult,
                limit: limit,
                cursor: cursor
            )
        )
    }

    @discardableResult
    func reconcileDeposits() async -> PolymarketDepositsScan? {
        do {
            return try await apiProvider.reconcileDeposits(depositWalletAddress: ownerAddressProvider.depositWalletAddress())
        } catch {
            PolymarketActivityFailure.log(error, while: "ask for a deposits scan")
            return nil
        }
    }
}

// MARK: - Filter

struct PolymarketActivityFilter: Hashable {
    let type: PolymarketActivityType?
    let redeemResult: PolymarketRedeemResult?
}
