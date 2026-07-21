//
//  SwapBalanceRestrictionFeatureChecker.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

enum SwapBalanceRestriction: Equatable {
    case none
    /// Zero total balance, toggle off: hide any sign of providers (legacy)
    case hideProviders
    /// Zero total balance, toggle on: quotes load but only DEX providers are shown
    case dexProvidersOnly
}

protocol SwapBalanceRestrictionFeatureChecker {
    func swapTotalBalanceRestriction(for token: SendSourceToken) async throws -> SwapBalanceRestriction
}

enum SwapBalanceRestrictionFeatureCheckerError: LocalizedError {
    case userWalletNotFound

    var errorDescription: String? {
        switch self {
        case .userWalletNotFound: "User wallet not found"
        }
    }
}

struct CommonSwapBalanceRestrictionFeatureChecker {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
}

// MARK: - SwapBalanceRestrictionFeatureChecker

extension CommonSwapBalanceRestrictionFeatureChecker: SwapBalanceRestrictionFeatureChecker {
    func swapTotalBalanceRestriction(for token: any SendSourceToken) async throws -> SwapBalanceRestriction {
        guard let userWalletModel = userWalletRepository.models[token.userWalletInfo.id] else {
            throw SwapBalanceRestrictionFeatureCheckerError.userWalletNotFound
        }

        guard userWalletModel.config.hasFeature(.isBalanceRestrictionActive) else {
            return .none
        }

        if userWalletRepository.models.count > 1 {
            return .none
        }

        let totalBalance = try await {
            // If total is loading
            if userWalletModel.totalBalance.isLoading {
                // Wait until finish state
                return try await userWalletModel.totalBalancePublisher.first { !$0.isLoading }.async()
            }

            return userWalletModel.totalBalance
        }()

        guard !totalBalance.hasAnyPositiveBalance else {
            return .none
        }

        return FeatureProvider.isAvailable(.hotWalletDexRatesUntilDeposit) ? .dexProvidersOnly : .hideProviders
    }
}
